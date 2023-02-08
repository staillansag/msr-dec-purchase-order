#!/bin/bash
. ./buildScripts/setEnv.sh

echo "Getting service principal credentials..."
if [ ! -f "${AZURESPCREDENTIALS_SECUREFILEPATH}" ]; then
  echo "Secure file path not present: ${AZURESPCREDENTIALS_SECUREFILEPATH}"
  exit 1
fi

chmod u+x "${AZURESPCREDENTIALS_SECUREFILEPATH}"
. "${AZURESPCREDENTIALS_SECUREFILEPATH}"

echo "Connecting to Azure with SP ${AZ_SP_ID}"
az login --service-principal -u ${AZ_SP_ID} -p ${AZ_SP_SECRET} --tenant ${AZ_TENANT_ID}

echo "Retrieving kubeconfig file for cluster ${CLUSTER_NAME}"
az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${CLUSTER_NAME} --overwrite-existing

kubectl get nodes || exit 1
