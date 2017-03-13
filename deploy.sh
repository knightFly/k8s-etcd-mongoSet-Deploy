#!/bin/bash

source ./util.sh

createK8sNamespace() {
	log::status "start createK8sNamespace..."
	namespaces=($(kubectl get ns | awk '{print $1}' | awk 'FNR>1'))
	for ns in ${namespaces[*]}; do
		if [[ "$ns" == "$K8S_NAMESPACE" ]]; then
			return
		fi
	done
	kubectl create namespace ${K8S_NAMESPACE}
}

configKubectl() {
	log::status "start createK8sNamespace..."
	kubectl config set-cluster ${CLUSTER_NAME} --server ${K8S_API_SERVER}
	kubectl config set-context ${CONTEXT_NAME} --cluster ${CLUSTER_NAME} --user ${USER_NAME} --namespace ${K8S_NAMESPACE}
	kubectl config set-credentials ${USER_NAME}
	kubectl config use-context ${CONTEXT_NAME}
}

getInfo() {
	log::status "list k8s rc"
	kubectl get rc  
	log::status "list k8s pod"
	kubectl get pod 
	log::status "list k8s svc"
	kubectl get svc 
}

configK8s() {
	for tool in ssh scp docker kubectl mongo jq curl; do
		if [[ ! -f $(which ${tool} 2>&1) ]]; then
			log::fatal "the binary ${tool} is required. Install it."
		fi
	done
	configKubectl
	createK8sNamespace
}


loadImages() {
    imagesDir=`pwd`/../images
    if [ ! -d $imagesDir ]; then
        log::fatal "there is not dir ${imagesDir}"
    fi
    for img in $(ls $imagesDir); do
	log::status "loading image ${img%.*}"
	imageFullName="$(sudo docker load < ${imagesDir}/${img} -q  | awk '{print $3}' | head -n 1)"
	imageName=${imageFullName##*/}
	log::status $imageName
	sudo docker tag ${imageFullName} ${REGISTRY_HOST}/${IMAGES_NAMESPACE}/${imageName} 2>&1 1>/dev/null
    	sudo docker push ${REGISTRY_HOST}/${IMAGES_NAMESPACE}/${imageName} 2>&1 1>/dev/null	
    done
}


startGitlabAndJenkins() {
	log::status "startGitlabAndJenkins"

	if [ ! -d ./jenkinsAndGit ]; then
		log::fatal "no jenkinsAndGit dir"
	fi

	for element in $(ls ./jenkinsAndGit); do
		if [ -d ./jenkinsAndGit/${element} ]; then
			shFile=$(ls ./jenkinsAndGit/${element}|grep '\.sh$')
			if [[ $? == 1 ]]; then
				continue
			fi
			for file in ${shFile}; do
				source ./jenkinsAndGit/${element}/$file	
			done	
			startUp
		fi	
	done
	getInfo
}


stopGitlabAndJenkins() {
	log::status "stopGitlabAndJenkins"
	if [ ! -d ./jenkinsAndGit ]; then
		log::fatal "no jenkinsAndGit dir"
	fi
	for element in $(ls ./jenkinsAndGit); do
		if [ -d ./jenkinsAndGit/${element} ]; then
			shFile=$(ls ./jenkinsAndGit/${element}/.yaml)
			if [[ $? == 1 ]]; then
				continue
			fi
			for file in ${shFile}; do
				kubectl delete -f ./jenkinsAndGit/${element}/.yaml/${file}	
				rm -f ./jenkinsAndGit/${element}/.yaml/${file}
			done
			rmdir ./jenkinsAndGit/${element}/.yaml
		fi	
	done
	ssh ${SSH_OPTS} "${JENKINS_NODE_HOST}" -t "
		if [ -d /var/jenkins ]; then
			sudo rm -rf /var/jenkins
		fi
	"
	ssh ${SSH_OPTS} "${GITLAB_NODE_HOST}" -t "
		if [ -d /srv/gitlab ]; then
			sudo rm -rf /srv/gitlab
		fi
	"
}

startMongoSet() {
    log::status "startMongoSet"
    mongoDir=`pwd`/mongosetDir

    if [ ! -d $mongoDir ]; then
        log::fatal "no mongoset dir : ${mongoDir}"
    fi

    for mg in $(ls $mongoDir); do
        if [ -f ${mongoDir}/$mg ]; then
            source ${mongoDir}/$mg 
            startUp
        fi
    done
}

stopMongoSet() {
    log::status "stopMongoSet"
    yamlDir=`pwd`/mongosetDir/yamlDir
    if [ ! -d $yamlDir ]; then
        log::fatal "no yaml dir : ${yamlDir}"
    fi
    for mgFile in $(ls $yamlDir); do
	kubectl delete -f ${yamlDir}/${mgFile} 
	rm -f ${yamlDir}/${mgFile}
    done
}



startEtcdCluster() {
    log::status "startEtcdCluster"
    etcdDir=`pwd`/etcdcluster

    if [ ! -d $etcdDir ]; then
        log::fatal "no mongoset dir : ${etcdDir}"
    fi

    for ed in $(ls $etcdDir); do
        if [ -f ${etcdDir}/$ed ]; then
            source ${etcdDir}/$ed 
            startUp
        fi
    done

}

stopEtcdCluster() { 
    log::status "stopEtcdCluster"
    yamlDir=`pwd`/etcdcluster/yamlDir
    if [ ! -d $yamlDir ]; then
        log::fatal "no yaml dir : ${yamlDir}"
    fi
    for file in $(ls $yamlDir); do
	kubectl delete -f ${yamlDir}/${file} 
	rm -f ${yamlDir}/${file}
    done

}



startMicroService() {
        log::status "startMicroService"

	if [ ! -d ./k8sSvc ]; then
		log::fatal "no k8sSvc dir"
	fi

	for element in $(ls ./k8sSvc); do
		if [ -d ./k8sSvc/${element} ]; then
			shFile=$(ls ./k8sSvc/${element}|grep '\.sh$')
			if [[ $? == 1 ]]; then
				continue
			fi
			for file in ${shFile}; do
				source ./k8sSvc/${element}/$file	
			done	
			startUp
		fi	
	done
	getInfo
}

stopMicroService() {
    log::status "stopMicroService"
    for element in $(ls ./k8sSvc); do
	if [ -d ./k8sSvc/${element} ]; then
		shFile=$(ls ./k8sSvc/${element}/.yaml)
		if [[ $? == 1 ]]; then
			continue
		fi
		for file in ${shFile}; do
			kubectl delete -f ./k8sSvc/${element}/.yaml/${file}	
			rm -f ./k8sSvc/${element}/.yaml/${file}
		done
		rmdir ./k8sSvc/${element}/.yaml
	fi	
    done

    kubectl get configmap --namespace=${K8S_NAMESPACE} > configmap
    sed -i '1d' .configmap
    configmaps=$(cat .configmap | awk '{print $1}')
    for cm in $configmaps; do
	kubectl delete configmap $cm	
    done
    rm configmap
}


case "$1" in
    configK8s)
	configK8s
    ;;
    loadimages)
        loadImages
    ;;
    createGitlabAndJenkins)
	startGitlabAndJenkins
    ;;
    deleteGitlabAndJenkins)
	stopGitlabAndJenkins
    ;;
    createMongoSet)
	startMongoSet
    ;;
    deleteMongoSet)
        stopMongoSet
    ;;
    createEtcdCluster)
	startEtcdCluster
    ;;
    deleteEtcdCluster)
	stopEtcdCluster
    ;;
    *)
    log::status "please input configK8s | loadimages | createGitlabAndJenkins | deleteGitlabAndJenkins | createMongoSet | deleteMongoSet | createEtcdCluster | deleteEtcdCluster | createMicroService | deleteMicroService"
    exit 1
esac
