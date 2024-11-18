#!/usr/bin/env bash
# Description: Downloads a file from a URL to a specified path, and can verify the file content with a provided md5 sum.
#
# Release Notes: Updated calculated name
#
# Usage: <url> <download file path> [expected md5 sum]
# <> are required
# [] are optional
# Example: https://www.nirsoft.net/utils/advancedrun.zip /tmp/advancedrun.zip
#  Downloads advancedrun.zip
# Example: https://www.nirsoft.net/utils/advancedrun.zip /tmp/advancedrun.zip 1f0913135878bb6cd30c1f3f6cf4b882
#  Downloads advancedrun.zip, verify's the provided md5 summed hash
#
# Notes: If the path doesn't exist this script will create the folders needed to place it there.
#  If you used /tmp/MyFiles/advancedrun.zip and the MyFiles folder didn't exist then it would create it.
#  The same for /tmp/MyFiles/Tools/advancedrun.zip, it would create MyFiles and Tools.

# Parameters

URL=${urlOrLink:=$1}
SAVE_PATH=${saveFilePath:=$2}
SUM=${fileHash:=$3}

URL_CHECK_REGEX='(https?|ftp|file)://[-[:alnum:]\+&@#/%?=~_|!:,.;]*[-[:alnum:]\+&@#/%=~_|]'
if [[ "${URL}" =~ ${URL_CHECK_REGEX} ]]; then
    echo "${URL} is a valid URL."
else
    echo "${URL} is an invalid URL."
    exit 1
fi

# Verify that the path provided is in a valid format, and create the folder structure if needed.
PATH_CHECK_REGEX='^(\/[^\/ ]*)+\/?$'
if [[ "${SAVE_PATH}" =~ ${PATH_CHECK_REGEX} ]]; then
    echo "${SAVE_PATH} is a valid path."
    FOLDER=$(dirname "${SAVE_PATH}")
    if [[ -d "${FOLDER}" ]]; then
        echo "Folder ${FOLDER} exists"
    else
        echo "Folder ${FOLDER} does not exist, creating."
        mkdir -p -v "${FOLDER}"
        if [ -f "${FOLDER}" ]; then
            echo "Created ${FOLDER}"
        else
            echo "Failed to created ${FOLDER}"
            exit 1
        fi
    fi
else
    echo "${SAVE_PATH} is an invalid path."
    exit 1
fi

function private_download() {
    # $1 = URL
    # $2 = File Path
    if [ "$(command -v wget)" ]; then
        echo "Downloading using wget"
        wget -O "$2" "$1"
    elif [ "$(command -v curl)" ]; then
        echo "Downloading using curl"
        curl "$1" --output "$2"
    else
        echo "Failed to find wget or curl."
        exit 1
    fi
}

function private_gethash() {
    FILE=$1
    HASH=$2
    WAS_ERROR=0
    if ! command -v md5 &>/dev/null; then
        # This should never happen
        echo "md5 could not be found"
        WAS_ERROR=1
    fi
    if [ "$(command -v md5)" ]; then
        CURRENT_HASH=$(md5 "${FILE}")
        # "##* " in "${CURRENT_HASH##* }" gets the last word in a string
        if [ "${HASH}" = "${CURRENT_HASH##* }" ]; then
            echo "File matches md5sum hash"
            WAS_ERROR=0
        else
            echo "File does not match md5sum hash"
            echo "Expected: ${CURRENT_HASH}"
            echo "File: ${HASH}"
            WAS_ERROR=1
        fi
    fi
    if [ ${WAS_ERROR} == 1 ]; then
        echo "Error verifying hash sum."
        exit 1
    fi
}

function private_validate() {
    if [ -f "$1" ]; then
        echo "File Downloaded."
        private_gethash "$1" "$2"
    else
        echo "Failed to download file."
        exit 1
    fi
}

# Download file
private_download "${URL}" "${SAVE_PATH}"
# If SUM is not empty
if [[ -n "${SUM}" ]]; then
    # Verify that the file was download
    # Compare hash from parameter to the file's calculated md5 sum
    private_validate "${SAVE_PATH}" "${SUM}"
fi





