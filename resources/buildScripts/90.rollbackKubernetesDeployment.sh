#!/bin/bash

kubectl rollout undo deployment/purchase-order --to-revision=${ROLLBACK_REVISION}

echo "Waiting for deployment to complete"
kubectl rollout status deployment purchase-order --timeout=300s && echo "Deployment complete" || exit 6

echo "Checking service readiness (by making a call to the metrics endpoint)"
curl -s -o /dev/null --location --request GET "https://decorders.sttlab.eu/metrics" && echo "Service is up" || exit 6
