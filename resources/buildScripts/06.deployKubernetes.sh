 #!/bin/bash
. ./resources/buildScripts/setEnv.sh

echo "Getting the ID of the current revision, in case we have to rollback to it"
rollbackRevision=$(kubectl rollout history deployment/customer-management -o jsonpath='{.metadata.generation}')
echo "##vso[task.setvariable variable=ROLLBACK_REVISION;]${rollbackRevision}"

imageTag="${SERVICE_MAJOR_VERSION}.${SERVICE_MINOR_VERSION}.${BUILD_BUILDID}"

echo "Deploying new microservice image"
sed 's/customer\-management\:latest/customer\-management\:'${imageTag}'/g' ./resources/deployment/kubernetes/01_msr-purchase-order_deployment.yaml | kubectl apply -f - || exit 6

echo "Deploying service (in case it does not already exist)"
kubectl apply -f ./resources/deployment/kubernetes/02_msr-purchase-order_service.yaml || exit 6

echo "Deploying ingress (in case it does not already exist)"
kubectl apply -f ./resources/deployment/kubernetes/99_ingress.yaml || exit 6

echo "Waiting for deployment to complete"
kubectl rollout status deployment purchase-order --timeout=300s && echo "Deployment complete" || exit 6

echo "Checking service readiness (by making a call to the metrics endpoint)"
curl -s -o /dev/null --location --request GET "https://decorders.sttlab.eu/metrics" && echo "Service is up" || exit 6