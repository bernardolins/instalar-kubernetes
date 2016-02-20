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

###### workers ######
workersip=$(cat $config | jsawk 'return this.workers')

workerips=$(echo $workersip | jsawk 'return this.ip')
workerhostnames=$(echo $workersip | jsawk 'return this.hostname')
workerinterfaces=$(echo $workersip | jsawk 'return this.interface')

echo $workerips $workerhostnames $workerinterfaces
