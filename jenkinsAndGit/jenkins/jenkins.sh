#!/bin/bash
source $(dirname "${BASH_SOURCE}")/../../util.sh

rootDir=$(dirname "${BASH_SOURCE}")
NAME=jenkins
NUM=1
YAMLDIR="${rootDir}/yamlDir"


createJenkins() {
	log::status "start createGitlabYaml..."
	cat << EOF > ${YAMLDIR}/${NAME}-rc.yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: ${NAME}
  labels:
    name: ${NAME}
  namespace: ${K8S_NAMESPACE}
spec:
  replicas: ${NUM}
  selector:
    name: ${NAME}
  template:
    metadata:
      labels:
        name: ${NAME}
    spec:
      containers:
      - image: ${REGISTRY_HOST}/${IMAGES_NAMESPACE}/jenkins
        name: ${NAME}
        imagePullPolicy: Always
        volumeMounts:
        - name: data-valume
          mountPath: /root/.jenkins
        - name: sock
          mountPath: /var/run/docker.sock
        ports:
        - containerPort: 8080
          hostPort: 80
      volumes:
      - name: data-valume
        hostPath: 
          path: /var/jenkins/jenkins-home/
      - name: sock
        hostPath:
          path: /var/run/docker.sock      
      restartPolicy: Always
      nodeSelector:
        nodename: jenkins
EOF

	cat << EOF > ${YAMLDIR}/${NAME}-svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: ${NAME}
  namespace: ${K8S_NAMESPACE}
  labels:
    name: ${NAME}
spec:
  selector:
    name: ${NAME}
  ports:
  - port: 80
    targetPort: 8080
EOF
}


startUp() {
	log::status "start ${NAME}"
	if [ ! -d ${YAMLDIR} ]; then
		mkdir ${YAMLDIR}
	fi
	if [[ $(kubectl describe node ${JENKINS_NODE_IP} | grep "nodename=jenkins" 2>&1 1>/dev/null; echo $?) == 1 ]]; then

		kubectl label node ${JENKINS_NODE_IP} nodename=jenkins
		if [[ $? != 0 ]]; then
			log::fatal "kubectl label node ${GITLAB_NODE_IP}"
		fi
	fi
	scp ${SSH_OPTS} -r ${rootDir}/jenkins-home  ${JENKINS_NODE_HOST}:~/  2>&1 1>/dev/null
        ssh ${SSH_OPTS} "${JENKINS_NODE_HOST}" -t  "
		if [ ! -d /var/jenkins ]; then
			sudo mkdir -p /var/jenkins
		fi
		sudo mv ./jenkins-home /var/jenkins"
	createJenkins
	createRcAndSvc "${NAME}" "${rootDir}" "${YAMLDIR}"
}
