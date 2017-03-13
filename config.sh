#!/bin/bash

#kubernetes master 的URL
K8S_API_SERVER=${K8S_API_SERVER:-"http://10.4.60.200:8080/api/k8s"}

#docker registry 的域名和端口
REGISTRY_HOST=${REGISTRY_HOST:-"localhub:5000"}

#docker registry 的URL
REGISTRY_URL=${REGISTRY_URL:-"http://10.4.60.176:5000"}

#集群中etcd的URL
ETCD_HOST=${ETCD_HOST:-"http://10.4.60.200:8080/api/etcd"}

#swagger_gen服务的指定节点的IP(swagger_gen 需要在指定节点启动)
SWAGGER_GEN_IP=${SWAGGER_GEN_IP:-"10.4.60.151"}

#jenkins 服务所在节点的IP（jenkins 服务需要在指定节点启动）
JENKINS_NODE_IP=${JENKINS_NODE_IP:-"10.4.60.178"}
#jenkins 服务所在节点的HOST（在IP前加上其所在主机名,如pana）
JENKINS_NODE_HOST=${JENKINS_NODE_IP:-"pana@10.4.60.178"} 

#gitlab 服务所在节点的IP(gitlab 服务需要在指定节点启动)
GITLAB_NODE_IP=${GITLAB_NODE:-"10.4.60.149"}
#gitlab 服务所在节点的HOST(主机名加IP)
GITLAB_NODE_HOST=${GITLAB_NODE:-"pana@10.4.60.149"}

#mongoNodes=${mongoNodes:-"mongo1 mongo2 mongo3"}
#mongoReplSet=${mongoReplSet:-"cloudtest"}

#kubernetes 的名称空间
K8S_NAMESPACE=${K8S_NAMESPACE:-"cloudtest"}

#docker 镜像的名称空间
IMAGES_NAMESPACE=${IMAGES_NAMESPACE:-"cloudtest"}

#CLUSTER_NAME 和 CONTEXT_NAME 的值和K8S_NAMESPACE的值保持一致
CLUSTER_NAME=${CLUSTER_NAME:-"cloudtest"}
CONTEXT_NAME=${CONTEXT_NAME:-"cloudtest"}
USER_NAME=${USER_NAME:-"huawei"}

#默认不需要改
SSH_OPTS="-oPort=22 -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=ERROR -C"

##**********************************************************
##先启动gitlab 和 jenkins ， 根据手册配置gitlab和jenkins。
##根据配置好的的数据修改以下变量。
##**********************************************************

#jenkins的用户名和密码("username:password")
##JenkinsIDPW=

#gitlab 的私有认证token 
##GitLabPrivateToken=

#jenkins的认证token
##JenkinsToken=

#jenkins的认证ID
##JenkinsCredentialsId=

