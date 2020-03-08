#!/bin/bash

# Initial environment variable checks
if [ -z "$CI_PACKAGE_NAME" ]; then
    echo "Environment variable CI_PACKAGE_NAME is missing. Aborting."
    exit 1
fi

# Default Kubernetes namespace to package name
if [ -z "$CI_K8S_NAMESPACE_NAME" ]; then
    export CI_K8S_NAMESPACE_NAME="$CI_PACKAGE_NAME"
    echo ::set-env name=CI_K8S_NAMESPACE_NAME::$CI_K8S_NAMESPACE_NAME
fi

#
# Source variables
#
# Commit SHA
export CI_COMMIT_SHA=${GITHUB_SHA}
echo ::set-env name=CI_COMMIT_SHA::$CI_COMMIT_SHA

# Commit SHA (short)
export CI_COMMIT_SHA_SHORT=$(echo ${GITHUB_SHA} | cut -c1-7)
echo ::set-env name=CI_COMMIT_SHA_SHORT::$CI_COMMIT_SHA_SHORT

#
# Helper variables
#
# Script Path
export CI_BOOTSTRAP_SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
echo ::set-env name=CI_BOOTSTRAP_SCRIPT_PATH::$CI_BOOTSTRAP_SCRIPT_PATH

# Date
export CI_DATE_YYYYMMDD=$(date '+%Y%m%d')
echo ::set-env name=CI_DATE_YYYYMMDD::$CI_DATE_YYYYMMDD

export CI_VERSION=$(/bin/bash ${CI_BOOTSTRAP_SCRIPT_PATH}/VERSION.sh)
echo ::set-env name=CI_VERSION::$CI_VERSION

#
# Package variables
#
if [ -z "$CI_PACKAGE_PATH" ]; then
    CI_PACKAGE_PATH=$CI_PACKAGE_NAME
fi
export CI_PACKAGE_PATH=$CI_PACKAGE_PATH
echo ::set-env name=CI_PACKAGE_PATH::$CI_PACKAGE_PATH

#
# Application helpers
#
case $CI_ENVIRONMENT in

  production)
    CI_APP_ENVIRONMENT=${CI_ENVIRONMENT}
    CI_APP_ENVIRONMENT_SHORT="prod"
    CI_APP_HOSTNAME_PREFIX=""
    ;;

  stage)
    CI_APP_ENVIRONMENT=${CI_ENVIRONMENT}
    CI_APP_ENVIRONMENT_SHORT="stage"
    CI_APP_HOSTNAME_PREFIX="stage."
    ;;

  test)
    CI_APP_ENVIRONMENT=${CI_ENVIRONMENT}
    CI_APP_ENVIRONMENT_SHORT="test"
    CI_APP_HOSTNAME_PREFIX="test."
    ;;

  development)
    CI_APP_ENVIRONMENT=${CI_ENVIRONMENT}
    CI_APP_ENVIRONMENT_SHORT="dev"
    CI_APP_HOSTNAME_PREFIX="dev."
    ;;

  local)
    CI_APP_ENVIRONMENT=${CI_ENVIRONMENT}
    CI_APP_ENVIRONMENT_SHORT="local"
    CI_APP_HOSTNAME_PREFIX="local."
    ;;

  *)
    CI_APP_ENVIRONMENT="unknown"
    CI_APP_ENVIRONMENT_SHORT="unknown"
    CI_APP_HOSTNAME_PREFIX="unknown."
    ;;
esac

export CI_APP_ENVIRONMENT=$CI_APP_ENVIRONMENT
export CI_APP_ENVIRONMENT_SHORT=$CI_APP_ENVIRONMENT_SHORT
export CI_APP_HOSTNAME_PREFIX=$CI_APP_HOSTNAME_PREFIX

echo ::set-env name=CI_APP_ENVIRONMENT::$CI_APP_ENVIRONMENT
echo ::set-env name=CI_APP_ENVIRONMENT_SHORT::$CI_APP_ENVIRONMENT_SHORT
echo ::set-env name=CI_APP_HOSTNAME_PREFIX::$CI_APP_HOSTNAME_PREFIX

#
# Docker Repository variables
#
# Default Kubernetes namespace to package name
if [ -z "$CI_REPOSITORY_NAME" ]; then
    export CI_REPOSITORY_NAME="$CI_PACKAGE_NAME"
    echo ::set-env name=CI_REPOSITORY_NAME::$CI_REPOSITORY_NAME
fi

# Determine tag prefix, otherwise default to package name
if [ -z "$CI_REPOSITORY_IMAGE_TAG_PREFIX" ]; then
    CI_REPOSITORY_IMAGE_TAG_PREFIX=$CI_PACKAGE_NAME
fi
export CI_REPOSITORY_IMAGE_TAG_PREFIX=$CI_REPOSITORY_IMAGE_TAG_PREFIX
echo ::set-env name=CI_REPOSITORY_IMAGE_TAG_PREFIX::$CI_REPOSITORY_IMAGE_TAG_PREFIX

# Image tag
export CI_REPOSITORY_IMAGE_TAG="${CI_REPOSITORY_IMAGE_TAG_PREFIX}-${CI_APP_ENVIRONMENT_SHORT}-${CI_DATE_YYYYMMDD}-${CI_COMMIT_SHA_SHORT}"
echo ::set-env name=CI_REPOSITORY_IMAGE_TAG::$CI_REPOSITORY_IMAGE_TAG

# Docker repository full path
export CI_REPOSITORY_IMAGE_PATH_FULL="${CI_REPOSITORY_HOSTNAME}/${CI_REPOSITORY_NAME}:${CI_REPOSITORY_IMAGE_TAG}"
echo ::set-env name=CI_REPOSITORY_IMAGE_PATH_FULL::$CI_REPOSITORY_IMAGE_PATH_FULL

# Docker repository path without tag
export CI_REPOSITORY_IMAGE_PATH_NO_TAG="${CI_REPOSITORY_HOSTNAME}/${CI_REPOSITORY_NAME}"
echo ::set-env name=CI_REPOSITORY_IMAGE_PATH_NO_TAG::$CI_REPOSITORY_IMAGE_PATH_NO_TAG

# Kubernetes environment variables
export CI_K8S_REPOSITORY_SECRET_NAME="${CI_REPOSITORY_NAME}-container-registry"
echo ::set-env name=CI_K8S_REPOSITORY_SECRET_NAME::$CI_K8S_REPOSITORY_SECRET_NAME

#
# Kubernetes config generation
#

# Kubernetes service name
export CI_K8S_SERVICE_NAME="${CI_PACKAGE_NAME}-${CI_APP_ENVIRONMENT_SHORT}"
echo ::set-env name=CI_K8S_SERVICE_NAME::$CI_K8S_SERVICE_NAME

# Generate component name suggestion, currently use image tag prefix
export CI_K8S_GENERATED_NAME="${CI_REPOSITORY_IMAGE_TAG_PREFIX}"
echo ::set-env name=CI_K8S_GENERATED_NAME::$CI_K8S_GENERATED_NAME

# Kubernetes config directory

# Only if CI_K8S_SOURCE_PATH is not set, try defining one
if [ -z "$CI_K8S_SOURCE_PATH" ]; then

    # Locate Kubernetes in package directory
    CI_K8S_SOURCE_PATH="./${CI_PACKAGE_PATH}/ops/config/kubernetes"

    # Check if there are files in the directory, otherwise default to root ops directory
    if [ ! -n "$(ls -A $CI_K8S_SOURCE_PATH 2>/dev/null)" ]; then
        
        CI_K8S_SOURCE_PATH_NEW="./ops/config/kubernetes"
        echo "INFO: Directory '${CI_K8S_SOURCE_PATH} is empty. Using '${CI_K8S_SOURCE_PATH_NEW}'."

        CI_K8S_SOURCE_PATH=$CI_K8S_SOURCE_PATH_NEW
    fi
fi

# Check if there is any config files present
if [ -n "$(ls -A $CI_K8S_SOURCE_PATH 2>/dev/null)" ]
then
   
    # Find *.yaml or *.yml files in Kubernetes source directory
    files=$(find $CI_K8S_SOURCE_PATH -regextype posix-extended -regex '^.*\.ya?ml' | sort)

    # Try to replace ${PLACEHOLDERS} with values from the ENV.
    awk 'FNR==1 && NR!=1 {print "---"}{print}' $files | envsubst > $CI_K8S_SOURCE_PATH/manifests.yaml
else
    echo
    #echo "No Kubernetes config files present in ${CI_K8S_SOURCE_PATH}."
fi

# Store the manifest content
export CI_K8S_GENERATED_MANIFESTS_FILE="${CI_K8S_SOURCE_PATH}/manifests.yaml"
echo ::set-env name=CI_K8S_GENERATED_MANIFESTS_FILE::$CI_K8S_GENERATED_MANIFESTS_FILE
echo

#
# Output variables for debugging
#

echo "==========================================================================="
echo "=                                                                          "
echo "= Sydnod CI                                                                "
echo "=                                                                          "
echo "==========================================================================="
echo

echo CI_VERSION
echo $CI_VERSION
echo

echo CI_BOOTSTRAP_SCRIPT_PATH
echo $CI_BOOTSTRAP_SCRIPT_PATH
echo

echo "==========================================================================="
echo "=> Helper variables                                                        "
echo "==========================================================================="
echo

echo CI_DATE_YYYYMMDD
echo $CI_DATE_YYYYMMDD
echo

echo "==========================================================================="
echo "=> Source Control variables                                                "
echo "==========================================================================="
echo

echo CI_COMMIT_SHA
echo $CI_COMMIT_SHA
echo

echo CI_COMMIT_SHA_SHORT
echo $CI_COMMIT_SHA_SHORT
echo

echo "==========================================================================="
echo "=> Package variables                                                       "
echo "==========================================================================="
echo

echo CI_PACKAGE_NAME
echo $CI_PACKAGE_NAME
echo

echo CI_PACKAGE_PATH
echo $CI_PACKAGE_PATH
echo

echo "==========================================================================="
echo "=> Application helpers                                                     "
echo "==========================================================================="
echo

echo CI_APP_ENVIRONMENT
echo $CI_APP_ENVIRONMENT
echo

echo CI_APP_ENVIRONMENT_SHORT
echo $CI_APP_ENVIRONMENT_SHORT
echo

echo CI_APP_HOSTNAME_PREFIX
echo $CI_APP_HOSTNAME_PREFIX
echo

echo "==========================================================================="
echo "=> Docker Repository variables                                             "
echo "==========================================================================="
echo

echo CI_REPOSITORY_IMAGE_TAG
echo $CI_REPOSITORY_IMAGE_TAG
echo

echo CI_REPOSITORY_IMAGE_TAG_PREFIX
echo $CI_REPOSITORY_IMAGE_TAG_PREFIX
echo

echo CI_REPOSITORY_IMAGE_PATH_FULL
echo $CI_REPOSITORY_IMAGE_PATH_FULL
echo

echo CI_REPOSITORY_IMAGE_PATH_NO_TAG
echo $CI_REPOSITORY_IMAGE_PATH_NO_TAG
echo

echo "==========================================================================="
echo "=> Kubernetes variables                                                    "
echo "==========================================================================="
echo

echo CI_K8S_SERVICE_NAME
echo $CI_K8S_SERVICE_NAME
echo

echo CI_K8S_SOURCE_PATH
echo $CI_K8S_SOURCE_PATH
echo

echo CI_K8S_GENERATED_MANIFESTS_FILE
echo $CI_K8S_GENERATED_MANIFESTS_FILE
echo

echo CI_K8S_REPOSITORY_SECRET_NAME
echo $CI_K8S_REPOSITORY_SECRET_NAME
echo

echo "==========================================================================="
echo "=> Kubernetes generated manifest                                           "
echo "==========================================================================="
echo

echo CI_K8S_GENERATED_MANIFESTS
cat $CI_K8S_GENERATED_MANIFESTS_FILE
echo

#
# For test validation
#
export CI_SCRIPT_PREPARE_COMPLETED="1"
echo ::set-env name=CI_SCRIPT_PREPARE_COMPLETED::$CI_SCRIPT_PREPARE_COMPLETED