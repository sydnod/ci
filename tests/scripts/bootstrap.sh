#!/bin/sh

# If we provide a argument, run the actual script
if [ ! -z "$1" ]; then

    # Prepare environment variables
    export CI_PACKAGE_NAME="ci"

    ./scripts/prepare.sh
fi 

# Check if prepare.sh was executed earlier
if [ -z "$CI_SCRIPT_PREPARE_COMPLETED" ]; then
    echo "ERR: Please execute /scripts/prepare.sh before running this test"

    exit 1
else 
    # Make sure that we run prepare.sh between each test
    unset CI_SCRIPT_PREPARE_COMPLETED
fi

if [ -z "$CI_PACKAGE_NAME" ]; then
    echo "CI_PACKAGE_NAME: Should not be empty"
    exit 1
fi

if [ "$CI_DATE_YYYYMMDD" == "$(date '+%Y%m%d')" ]; then
    echo "CI_DATE_YYYYMMDD: Should not be '$(date '+%Y%m%d')'."
    exit 1
fi