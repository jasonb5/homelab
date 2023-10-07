#!/bin/bash

kubectl -n ${NAMESPACE} patch clusterpolicy/cluster-policy --type merge --patch-file=/dev/stdin <<-EOF
spec:
  devicePlugin:
    config:
      name: time-slicing-config
      default: any
EOF
