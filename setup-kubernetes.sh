#!/bin/bash
set -e

args=$(getopt -l "config-dir:install-dir:help" -o "c:i:h" -- "$@")

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
     -i|--install-dir)
      install="$2"
      shift
      ;;
     -t|--type)
      type="$2"
      shift
      ;;
  esac
  shift
done

kubernetes_dir=/etc/kubernetes
kubernetes_multinode_dir=/srv/kubernetes

default_manifest_dir=$kubernetes_dir/manifests
kubernetes_tls_dir=$kubernetes_dir/ssl
multinode_config_dir=$kubernetes_multinode_dir/manifests

systemd_dir=/etc/systemd/system

echo "installing kubernetes - make sure you have all config files in config directory!"
echo "if you are not sure refer to https://coreos.com/kubernetes/docs/latest/getting-started.html"

echo "creating directories ..."
mkdir -p $kubernetes_dir
mkdir -p $default_manifest_dir
mkdir -p $kubernetes_tls_dir
mkdir -p $kubernetes_multinode_dir
mkdir -p $multinode_config_dir

echo "copying kubelet.unit to $systemd_dir ..."
cp $config/kubelet.unit $systemd_dir

if [ $type = "master" ]; then
  echo "copying manifests to $default_manifest_dir ..."
  cp $config/kube-api-server.yaml $default_manifest_dir
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
