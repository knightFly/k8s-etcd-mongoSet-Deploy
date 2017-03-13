#!/binbash
source $(dirname "${BASH_SOURCE}")/../util.sh

rootDir=$(dirname "${BASH_SOURCE}")
YAMLDIR="${rootDir}/yamlDir"

etcdNodes=${etcdNodes:-"etcd0 etcd1 etcd2"}


# {1} is etcdName
createEtcd() {
	log::status "start createEtcd ${1}..."
	cat << EOF > ${YAMLDIR}/${1}-rc.yaml
apiVersion: v1
kind: ReplicationController
metadata: 
  name: ${1}
  labels:
    name: ${1}
  namespace: ${K8S_NAMESPACE}
spec:
  replicas: 1
  template:
    metadata:
      labels:
        name: ${1}
    spec:
      containers:
      - name: ${1}
        image: ${REGISTRY_HOST}/${IMAGES_NAMESPACE}/etcd-amd64:2.2.5
        args:
        - /bin/bash
        - -c
        - etcd -name ${1} \
-data-dir /var/etcd/data \
-listen-peer-urls http://0.0.0.0:2380 \
-listen-client-urls http://0.0.0.0:4001 \
-initial-advertise-peer-urls http://${1}:2380 \
-initial-cluster etcd0=http://etcd0:2380,etcd1=http://etcd1:2380,etcd2=http://etcd2:2380 \
-initial-cluster-state new \
-initial-cluster-token etcd-cluster \
-advertise-client-urls http://${1}:4001
        ports:
        - containerPort: 2380
          name: peerPort
        - containerPort: 4001
          name: clientPort
      restartPolicy: Always
EOF
	cat << EOF > ${YAMLDIR}/${1}-svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: ${1}
  labels:
    name: ${1}
  namespace: ${K8S_NAMESPACE}
spec:
  selector:
    name: ${1}
  ports:
  - port: 2380
    targetPort: 2380
    name: peerPort
  - port: 4001
    targetPort: 4001
    name: clientPort
EOF
}

startUp() {
	log::status "start etcdcluster"
	if [ ! -d ${YAMLDIR} ]; then
		mkdir ${YAMLDIR}
	fi
	
	for node in ${etcdNodes[*]}; do
		createEtcd ${node}	
		#createRcAndSvc "${node}" "${rootDir}" "${YAMLDIR}"
	done
}
