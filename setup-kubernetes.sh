#!/bin/bash
set -e

args=$(getopt -l "config-dir:ssl-dir:version:type:help" -o "c:s:v:t:h" -- "$@")

eval set -- "$args"

while [ $# -ge 1 ]; do
  case "$1" in
    --)
      # No more options left.
      shift
      break
      ;;
    -c|--config-dir)
      config="$2"
      shift
      ;;
    -s|--ssl-dir)
      ssl="$2"
      shift
      ;;
    -v|--kube-version)
      version="$2"
      shift
      ;;
    -t|--type)
      type="$2"
      shift
      ;;
  esac
  shift
done

if [ ! $version ]; then
  echo "---- Must specify a version!"
  echo "format: v1.x.x"
  exit 1
fi

kubernetes_dir=/etc/kubernetes
kubernetes_multinode_dir=/srv/kubernetes

default_manifest_dir=$kubernetes_dir/manifests
kubernetes_tls_dir=$kubernetes_dir/ssl
multinode_config_dir=$kubernetes_multinode_dir/manifests

systemd_dir=/etc/systemd/system

if [ ! -f  /opt/bin/kubelet ]; then
  echo "download kubelet binary from https://storage.googleapis.com/"
  echo "version: $version"
  
  wget https://storage.googleapis.com/kubernetes-release/release/$version/bin/linux/amd64/kubelet
  
  chmod +x kubelet
  
  mkdir -p /opt/bin
  mv kubelet /opt/bin
fi

echo "installing kubernetes - make sure you have all config files in config directory!"
echo "if you are not sure refer to https://coreos.com/kubernetes/docs/latest/getting-started.html"

echo "creating directories ..."
mkdir -p $kubernetes_dir
mkdir -p $default_manifest_dir
mkdir -p $kubernetes_tls_dir
mkdir -p $kubernetes_multinode_dir
mkdir -p $multinode_config_dir

echo "copying kubelet.service to $systemd_dir ..."
cp $config/kubelet.service $systemd_dir

if [ $type = "master" ]; then
  echo "copying manifests to $default_manifest_dir ..."
  cp $config/kube-apiserver.yaml $default_manifest_dir
  cp $config/kube-proxy.yaml $default_manifest_dir
  cp $config/kube-podmaster.yaml $default_manifest_dir

  echo "copying manifests to $multinode_config_dir ..."
  cp $config/kube-controller-manager.yaml $multinode_config_dir
  cp $config/kube-scheduler.yaml $multinode_config_dir

elif [ $type = "worker" ]; then
  cp $config/kube-proxy.yaml $default_manifest_dir
  cp $config/worker-kubeconfig.yaml $kubernetes_dir
else
  echo "invalid type, try master or worker"
  exit -1
fi

if [ $ssl != "" ]; then 
  echo "copying ssl certificates to $kubernetes_dir"
  cp $ssl/* $kubernetes_tls_dir
else
  echo "warning: no ssl path specified!"
fi
