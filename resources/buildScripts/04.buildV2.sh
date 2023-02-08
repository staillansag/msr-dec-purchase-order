#!/bin/bash
. ./resources/buildScripts/setEnv.sh

echo "Getting service principal credentials..."
if [ ! -f "${CRCREDENTIALS_SECUREFILEPATH}" ]; then
  echo "Secure file path not present: ${CRCREDENTIALS_SECUREFILEPATH}"
  exit 1
fi

chmod u+x "${CRCREDENTIALS_SECUREFILEPATH}"
. "${CRCREDENTIALS_SECUREFILEPATH}"

if [ -z ${CR_ID+x} ]; then
  echo "Secure information has not been sourced correctly"
  exit 2
fi

echo "Logging in to repository ${CR_URL}"
docker login -u "${CR_ID}" -p "${CR_SECRET}" "${CR_URL}"  || exit 3

echo "Building tag ${SERVICE_IMAGE_TAG_BASE}"
docker build \
  --build-arg __from_img=${BASE_IMAGE_TAG} \
  -t "${SERVICE_IMAGE_TAG_BASE}" . || exit 4

dockerHostName="$SERVICE_IMAGE_REPO"-$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w ${1:-10} | head -n 1 | tr '[:upper:]' '[:lower:]')

echo "Environment file for testing: ${DOCKERENV_SECUREFILEPATH}"
dockerId=$(docker run --name ${dockerHostName} -d --network sag --env-file ${DOCKERENV_SECUREFILEPATH} "${SERVICE_IMAGE_TAG_BASE}")

echo "Checking availability of http://${dockerHostName}:5555"
max_retry=10
counter=1
until curl -s http://${dockerHostName}:5555
do
   sleep 10
   [[ counter -gt $max_retry ]] && echo "Docker container did not start" && exit 1
   echo "Trying again to access MSR admin URL. Try #$counter"
   ((counter++))
done

echo "Basic sanity check of the generated docker image"
curl -s -o /dev/null --location --request GET "http://${dockerHostName}:5555/customer-management/customers" \
--header 'Authorization: Basic QWRtaW5pc3RyYXRvcjptYW5hZ2U=a' && echo "Test passed" || exit 4 

crtTag="${SERVICE_IMAGE_TAG_BASE}:${SERVICE_MAJOR_VERSION}.${SERVICE_MINOR_VERSION}.${BUILD_BUILDID}"

echo "Tagging ${SERVICE_IMAGE_TAG_BASE} to ${crtTag}"
docker tag "${SERVICE_IMAGE_TAG_BASE}" "${crtTag}"

echo "==================> BUILD_REASON = ${BUILD_REASON}"

echo "Pushing tag ${crtTag}"
docker push "${crtTag}"

if [[ "${BUILD_SOURCEBRANCHNAME}" == "main" ]]; then
  echo "Pushing tag ${SERVICE_IMAGE_TAG_BASE}"
  docker push "${SERVICE_IMAGE_TAG_BASE}"
fi

echo "Logging out"
docker logout "${CR_URL}"

echo "Push completed"

echo "Cleaning docker container"
docker stop ${dockerId}
docker rm ${dockerId}
