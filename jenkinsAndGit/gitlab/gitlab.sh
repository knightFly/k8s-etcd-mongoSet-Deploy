#!/bin/bash
source $(dirname "${BASH_SOURCE}")/../../util.sh
rootDir=$(dirname "${BASH_SOURCE}")


NAME=gitlab
NUM=1
YAMLDIR="${rootDir}/yamlDir"

createGitlab() {
	log::status "start createGitlabYaml..."
	cat << EOF > ${YAMLDIR}/${NAME}-rc.yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: ${NAME}
  namespace: ${K8S_NAMESPACE}
spec:
  replicas: ${NUM}
  template:
    metadata:
      labels:
        name: ${NAME}
    spec:
      containers:
      - image: ${REGISTRY_HOST}/${IMAGES_NAMESPACE}/gitlab-ce:v2
        name: ${NAME}
        imagePullPolicy: Always
        command:
        - /bin/bash
        - -c
        - /assets/wrapper
        env:
        - name: GITLAB_OMNIBUS_CONFIG
          value: "external_url 'http://${GITLAB_NODE_IP}';gitlab_rails['gitlab_shell_ssh_port']=2289"
        volumeMounts:
        - mountPath: /etc/gitlab 
          name: config
        - mountPath: /var/log/gitlab 
          name: log
        - mountPath: /var/opt/gitlab 
          name: data
        ports:
        - containerPort: 80
          hostPort: 80
          name: httpport
        - containerPort: 22
          hostPort: 2289
          name: sshport
        - containerPort: 443
          hostPort: 443
          name: httpsport
      volumes:
      - hostPath:
          path: /srv/gitlab/config
        name: config
      - hostPath:
          path: /srv/gitlab/logs
        name: log
      - hostPath:
          path: /srv/gitlab/data
        name: data
      restartPolicy: Always
      nodeSelector:
        cloudtest: gitlab
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
    targetPort: 80
EOF
}


startUp() {
	log::status "start ${NAME}"
	if [ ! -d ${YAMLDIR} ]; then
		mkdir ${YAMLDIR}
	fi
	if [[ $(kubectl describe node ${GITLAB_NODE_IP} | grep "cloudtest=gitlab" 2>&1 1>/dev/null; echo $?) == 1 ]]; then

		kubectl label node ${GITLAB_NODE_IP} cloudtest=gitlab
		if [[ $? != 0 ]]; then
			log::fatal "kubectl label node ${GITLAB_NODE_IP}"
		fi
	fi
	createGitlab
	createRcAndSvc "${NAME}" "${rootDir}" "${YAMLDIR}"
}
