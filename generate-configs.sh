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

if [ -z "$output" ]; then
  output="."
fi

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

###### kubectl ###### 
kubectl=$(cat $file | jsawk 'return this.kubectl')

kubectl_ips=$(echo $kubectl | jsawk -n 'out(this.ip)')
kubectl_hostnames=$(echo $kubectl | jsawk -n 'out(this.hostname)')
kubectl_interfaces=$(echo $kubectl | jsawk -n 'out (this.interface)')

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
KUBERNETES_VERSION=$version

###### Setting up variables ######

###### Defaults ######
POD_NETWORK=10.2.0.0/16
SERVICE_IP_RANGE=10.3.0.0/24
K8S_SERVICE_IP=10.3.0.1
DNS_SERVICE_IP=10.3.0.10
KUBERNETES_VERSION=$version

###### Cluster specific ######
TOKEN=$token
ETCD_ENDPOINTS=$(set_etcd_endpoints)
INITIAL_CLUSTER=$(set_initial_cluster)

#### MASTER ####
ADVERTISE_IP=$master_ip
NAME=$master_hostname
NETWORK_INTERFACE=$master_interface
MASTER_HOST=$master_ip

output_file=cloud-config.yaml

f=$(find $config -name '*kubernetes*master*.yaml' -or -name '*kubernetes*master*.yml')
mkdir -p $output/$token/master/$NAME
touch $output/$token/master/$NAME/$output_file
eval "echo \"`cat $f`\"" > $output/$token/master/$NAME/$output_file

#### WORKER ####
worker_ip_array=($worker_ips)
worker_hostname_array=($worker_hostnames)
woerker_interface_array=($worker_interfaces)

for (( i=0; i<${#worker_ip_array[@]}; i++ )); do
  ADVERTISE_IP=${worker_ip_array[$i]}
  NAME=${worker_hostname_array[$i]}
  NETWORK_INTERFACE=${woerker_interface_array[$i]}

  mkdir -p $output/$token/worker/$NAME

  f=$(find $config -name '*kubernetes*worker*.yaml' -or -name '*kubernetes*worker*.yml')
  touch $output/$token/worker/$NAME/$output_file
  eval "echo \"`cat $f`\"" > $output/$token/worker/$NAME/$output_file
done

#### ETCD ####
etcd_ip_array=($etcd_ips)
etcd_hostname_array=($etcd_hostnames)
etcd_interface_array=($etcd_interfaces)

for (( i=0; i<${#etcd_ip_array[@]}; i++ )); do
  ADVERTISE_IP=${etcd_ip_array[$i]}
  NAME=${etcd_hostname_array[$i]}
  NETWORK_INTERFACE=${etcd_interface_array[$i]}

  mkdir -p $output/$token/etcd/$NAME

  f=$(find $config -name '*etcd*.yaml' -or -name '*etcd*.yml')
  touch $output/$token/etcd/$NAME/$output_file
  eval "echo \"`cat $f`\"" > $output/$token/etcd/$NAME/$output_file
done

#### KUBECTL ####
kubectl_ip_array=($kubectl_ips)
kubectl_hostname_array=($kubectl_hostnames)
kubectl_interface_array=($kubectl_interfaces)

for (( i=0; i<${#kubectl_ip_array[@]}; i++ )); do
  ADVERTISE_IP=${kubectl_ip_array[$i]}
  NAME=${kubectl_hostname_array[$i]}
  NETWORK_INTERFACE=${kubectl_interface_array[$i]}
  MASTER_HOST=$master_ip

  mkdir -p $output/$token/kubectl/$NAME

  f=$(find $config -name '*kubectl*.yaml' -or -name '*kubectl*.yml')
  touch $output/$token/kubectl/$NAME/$output_file
  eval "echo \"`cat $f`\"" > $output/$token/kubectl/$NAME/$output_file
done

###### SSL assets ######
source generate-certificates.sh
