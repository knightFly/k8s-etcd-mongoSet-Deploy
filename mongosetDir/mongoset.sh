#!/binbash
source $(dirname "${BASH_SOURCE}")/../util.sh

rootDir=$(dirname "${BASH_SOURCE}")
YAMLDIR="${rootDir}/yamlDir"

mongoNodes=${mongoNodes:-"mongo1 mongo2 mongo3"}
mongoReplSet=${mongoReplSet:-"cloudtest"}

# {1} is mongoName

createMongo() {
	log::status "start createMongo ${1}..."
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
        name: mongo
        role: ${1}
    spec:
      containers:
      - name: ${1}
        image: ${REGISTRY_HOST}/${IMAGES_NAMESPACE}/mongo-ram
        args:
        - /bin/bash
        - -c
        - mongod --dbpath /data/db --nojournal --smallfiles --noprealloc  --replSet ${mongoReplSet}
        env:
        - name: DATA_SIZE
          value: "300"
        ports:
        - containerPort: 27017
        readinessProbe:
          tcpSocket:
            port: 27017
          initialDelaySeconds: 10
          timeoutSeconds: 3
        securityContext:
          privileged: true
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
    name: mongo
    role: ${1}
  ports:
  - port: 27017
EOF
}


configMongoSet() {
	log::status "start configMongoSet..."
	mongoNodeArray=($mongoNodes)
	mongoNode1=${mongoNodeArray[0]}
	mongoNode2=${mongoNodeArray[1]}
	mongoNode3=${mongoNodeArray[2]}

	cat << EOF > ${rootDir}/.config.js
var initconf={"_id":"${mongoReplSet}","members":
    [
	{ "_id":0,"host":"${mongoNode1}.${K8S_NAMESPACE}:27017","priority":10 },
	{ "_id":1,"host":"${mongoNode2}.${K8S_NAMESPACE}:27017","priority":9 },
	{ "_id":2,"host":"${mongoNode3}.${K8S_NAMESPACE}:27017","priority":9 }
    ] 
} 
rs.initiate(initconf)
var conf = rs.conf()
print(JSON.stringify(conf,null,"\t"))
EOF

	i=1
	while [[ $i == 1 ]]; do
		i=0
		for status in $(kubectl describe pod mongo | grep Status: | awk '{print $2}'); do
			if [[ ${status} != "Running" ]]; then
				i=1
			fi
		done	
		log::status "wait mongo start running"
		sleep 3
	done
	mongoNodeIp=$(kubectl describe pod ${mongoNode1} | grep IP | sed -E 's/IP:[[:space:]]+//')
	log::status "${rootDir}/.config.js"
	mongo --host ${mongoNodeIp}:27017 ${rootDir}/.config.js

}

startUp() {
	log::status "start mongoset"
	if [ ! -d ${YAMLDIR} ]; then
		mkdir ${YAMLDIR}
	fi
	
	for node in ${mongoNodes[*]}; do
		createMongo ${node}	
		createRcAndSvc "${node}" "${rootDir}" "${YAMLDIR}"
	done
	configMongoSet
}
