#!/bin/bash

args=$(getopt -l "dir:help" -o "d:h" -- "$@")

eval set -- "$args"

while [ $# -ge 1 ]; do
  case "$1" in
    --)
      # No more options left.
      shift
      break
      ;;
     -d|--dir)
      config="$2"
      shift
      ;;
    -h|--help)
      printUsage
      exit 0
      ;;
  esac
  shift
done

###### kubernetes ######
version=$(cat $config | jsawk 'return this.version')
token=$(cat $config | jsawk 'return this.token')

####### master #######
masterip=$(cat $config | jsawk 'return this.master.ip')
masterhostname=$(cat $config | jsawk 'return this.master.hostname')
masterinterface=$(cat $config | jsawk 'return this.master.interface')
masteriphostname=$(cat $config | jsawk -n 'out (this.master.hostname + "=http://" + this.master.ip + ":2380")')

###### workers ######
workers=$(cat $config | jsawk 'return this.workers')

workerips=$(echo $workers | jsawk -n 'out(this.ip)')
workerhostnames=$(echo $workers | jsawk -n 'out(this.hostname)')
workerinterfaces=$(echo $workers | jsawk -n 'out (this.interface)')

workeriphostname=$(echo $workers | jsawk -n 'out (this.hostname + "=http://" + this.ip + ":2380")')

function set_endpoints {
  endpoints=""

  for ip in $masterip; do
    if [ -n "$endpoints" ]; then
      endpoints="$endpoints,"
    fi

    address="http://$ip:2379" 
    endpoints="$endpoints$address"
  done

  for ip in $workerips; do
    if [ -n "$endpoints" ]; then
      endpoints="$endpoints,"
    fi

    address="http://$ip:2379" 
    endpoints="$endpoints$address"
  done

  echo $endpoints
}

function set_initial_cluster {
  nodes=""

  for node in $masteriphostname; do
    if [ -n "$nodes" ]; then
      nodes="$nodes,"
    fi

    nodes="$nodes$node"
  done

  for node in $workeriphostname; do
    if [ -n "$nodes" ]; then
      nodes="$nodes,"
    fi

    nodes="$nodes$node"
  done

  echo $nodes
}

###### Setting up variables ######

###### Defaults ######
POD_NETWORK=10.2.0.0/16
SERVICE_IP_RANGE=10.3.0.0/24
K8S_SERVICE_IP=10.3.0.1
DNS_SERVICE_IP=10.3.0.10

###### Cluster specific ######

ETCD_ENDPOINTS=$(set_endpoints)
INITIAL_CLUSTER=$(set_initial_cluster)

echo $INITIAL_CLUSTER
