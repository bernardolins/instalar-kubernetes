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
master_ip=$(cat $file | jsawk 'return this.master.ip')
master_hostname=$(cat $file | jsawk 'return this.master.hostname')
master_interface=$(cat $file | jsawk 'return this.master.interface')

###### workers ######
workers=$(cat $file | jsawk 'return this.workers')

worker_ips=$(echo $workers | jsawk -n 'out(this.ip)')
worker_hostnames=$(echo $workers | jsawk -n 'out(this.hostname)')
worker_interfaces=$(echo $workers | jsawk -n 'out (this.interface)')

###### etcd ######
etcd=$(cat $file | jsawk 'return this.etcd')

etcd_ips=$(echo $etcd | jsawk -n 'out(this.ip)')
etcd_hostnames=$(echo $etcd | jsawk -n 'out(this.hostname)')
etcd_nodes=$(echo $etcd | jsawk -n 'out (this.hostname + "=http://" + this.ip + ":2380")')
etcd_interfaces=$(echo $etcd | jsawk -n 'out (this.interface)')

function set_etcd_endpoints {
  endpoints=""

  for ip in $etcd_ips; do
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

  for node in $etcd_nodes; do
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
VERSION=$version

###### Setting up variables ######

###### Defaults ######
POD_NETWORK=10.2.0.0/16
SERVICE_IP_RANGE=10.3.0.0/24
K8S_SERVICE_IP=10.3.0.1
DNS_SERVICE_IP=10.3.0.10
VERSION=$version

###### Cluster specific ######
TOKEN=$token
ETCD_ENDPOINTS=$(set_etcd_endpoints)
INITIAL_CLUSTER=$(set_initial_cluster)

ADVERTISE_IP=$master_ip
NAME=$master_hostname
NETWORK_INTERFACE=$master_interface
MASTER_HOST=$master_ip

output_file=cloud-config.yaml

#### MASTER ####
f=$(find $config -name '*kubernetes*master*.yaml' -or -name '*kubernetes*master*.yml')
mkdir -p $token/master/$NAME
touch $token/master/$NAME/$output_file
eval "echo \"`cat $f`\"" > $token/master/$NAME/$output_file

#### WORKER ####
iparray=($worker_ips)
hostnamearray=($worker_hostnames)
interfacearray=($worker_interfaces)

for (( i=0; i<${#iparray[@]}; i++ )); do
  ADVERTISE_IP=${iparray[$i]}
  NAME=${hostnamearray[$i]}
  NETWORK_INTERFACE=${interfacearray[$i]}

  mkdir -p $token/worker/$NAME

  f=$(find $config -name '*kubernetes*worker*.yaml' -or -name '*kubernetes*worker*.yml')
  touch $token/worker/$NAME/$output_file
  eval "echo \"`cat $f`\"" > $token/worker/$NAME/$output_file
done

#### ETCD ####
iparray=($etcd_ips)
hostnamearray=($etcd_hostnames)
interfacearray=($etcd_interfaces)

for (( i=0; i<${#iparray[@]}; i++ )); do
  ADVERTISE_IP=${iparray[$i]}
  NAME=${hostnamearray[$i]}
  NETWORK_INTERFACE=${interfacearray[$i]}

  mkdir -p $token/etcd/$NAME

  f=$(find $config -name '*etcd*.yaml' -or -name '*etcd*.yml')
  touch $token/etcd/$NAME/$output_file
  eval "echo \"`cat $f`\"" > $token/etcd/$NAME/$output_file
done

###### SSL assets ######
source generate-certificates.sh
