#!/bin/bash

args=$(getopt -l "dir:output-dir:file:help" -o "d:o:f:h" -- "$@")

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
     -o|--output-dir)
      output="$2"
      shift
      ;;
     -f|--file)
      file="$2"
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
version=$(cat $file | jsawk 'return this.version')
token=$(cat $file | jsawk 'return this.token')

####### master #######
masterip=$(cat $file | jsawk 'return this.master.ip')
masterhostname=$(cat $file | jsawk 'return this.master.hostname')
masterinterface=$(cat $file | jsawk 'return this.master.interface')
masteriphostname=$(cat $file | jsawk -n 'out (this.master.hostname + "=http://" + this.master.ip + ":2380")')

###### workers ######
workers=$(cat $file | jsawk 'return this.workers')

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

    address="http://$NAME:2379" 
    endpoints="$endpoints$address"
  done

  for ip in $workerips; do
    if [ -n "$endpoints" ]; then
      endpoints="$endpoints,"
    fi

    address="http://$NAME:2379" 
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
TOKEN=$token
ETCD_ENDPOINTS=$(set_endpoints)
INITIAL_CLUSTER=$(set_initial_cluster)

###### Generate master files ######
ADVERTISE_IP=$masterip
NAME=$masterhostname
NETWORK_INTERFACE=$masterinterface

mkdir -p $token/master/$NAME

for f in $(find $config/master -type f -printf "%f\n"); do
  touch $token/master/$NAME/$f
  eval "echo \"`cat $config/master/$f`\"" > $token/master/$NAME/$f
done

###### Generate worker files ######
iparray=($workerips)
hostnamearray=($workerhostnames)
interfacearray=($workerinterfaces)

for (( i=0; i<${#iparray[@]}; i++ )); do
  MASTER_HOST=$masterip
  ADVERTISE_IP=${iparray[$i]}
  NAME=${hostnamearray[$i]}
  NETWORK_INTERFACE=${interfacearray[$i]}

  mkdir -p $token/worker/$NAME

  for f in $(find $config/worker -type f -printf "%f\n"); do
    touch $token/worker/$NAME/$f
    eval "echo \"`cat $config/worker/$f`\"" > $token/worker/$NAME/$f
  done
done

###### SSL assets ######
source generate-certificates.sh
