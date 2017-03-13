#!/bin/bash

source ./config.sh

log::status() {
  timestamp=$(date +"[%m%d %H:%M:%S]")
  echo "+++ $timestamp $1"
  shift
  for message; do
    echo "    $message"
  done
}


log::fatal() {
  timestamp=$(date +"[%m%d %H:%M:%S]")
  echo "!!! $timestamp ${1-}"
  shift
  for message; do
    echo "    $message"
  done
  exit 1
}


# $1 is name
# $2 is rootDir
# $3 is yamldir

createRcAndSvc() {
	log::status "start ${1} createRcAndSvc..."

	for file in $(ls ${3}); do
		if [[ $file == "${1}-rc.yaml" || $file == "${1}-svc.yaml" ]] ; then
			kubectl create -f ${3}/$file 
		fi
	done

	i=1
	while [[ $i == 1 ]]; do
		i=0
		for status in $(kubectl describe pod ${1} | grep Status: | awk '{print $2}'); do
			if [[ ${status} != "Running" ]]; then
				i=1
			fi
		done	
		log::status "wait ${1} start running"
		sleep 3
	done
}


