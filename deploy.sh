#!/bin/bash

ENV_TO_DEPLOY=$1

if [[ -z "${ENV_TO_DEPLOY}" ]]; then
    echo "Missing ENV_TO_DEPLOY env"
    exit 1
fi

kubectl --kubeconfig=./kubeconfig apply -f "deploy/${ENV_TO_DEPLOY}"
