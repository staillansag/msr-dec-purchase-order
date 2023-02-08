#!/bin/bash

# Pipeline parameters
export CR_URL="docker.io"
export CR_ID="staillansag"
export BASE_IMAGE_REPO="webmethods-microservicesruntime"
export BASE_IMAGE_VERSION="10.15.0.1-jk"
export BASE_IMAGE_TAG="${CR_ID}/${BASE_IMAGE_REPO}:${BASE_IMAGE_VERSION}"

export SERVICE_IMAGE_REPO="msr-dec-purchase-order"
export SERVICE_IMAGE_TAG_BASE="${CR_ID}/${SERVICE_IMAGE_REPO}"
export SERVICE_MAJOR_VERSION="0"
export SERVICE_MINOR_VERSION="0"

export CLUSTER_NAME=sttaks
export RESOURCE_GROUP=aks_rg