#!/bin/sh
#
# Name:            backup-unzip.sh
# Description:     Take given gpg file ($1) decrypt and extract tar archive
#
# Author:          mail@rhab.de
# Version:         0.12

## Debuging
#set -x

## Put the passphrase for the symmetric gpg encryption into this file
## File is expected to be located in same directory as backup-[un]zip.sh script
## File needs to be owned by same user and needs permissions "600"
## Passphrase goes into first line (no other content)
PASSPHRASE_FILENAME="backup-passphrase.txt"


## setup basics
TAR="/bin/tar"
GPG="/usr/bin/gpg"
SED="/bin/sed"

startTimer() {
    START_TIME=$(date)
    S_TIME=$(date +%s)
}

endTimer() {
    END_TIME=$(date)
    E_TIME=$(date +%s)
    DURATION=$(echo $((E_TIME - S_TIME)))

    #calculate overall completion time
    if [ ${DURATION} -le 60 ] ; then
        echo "Ended: "${END_TIME}" - Duration: ${DURATION} Seconds"
    else
        echo "Ended: "${END_TIME}" - Duration: $(awk 'BEGIN{ printf "%.2f\n", '${DURATION}'/60}') Minutes"
    fi
}

startTimer

## setup full path for passphrase file and check it
SCRIPTPATH=$(dirname $0)
PASSPHRASE_FILE_FULL_PATH=${SCRIPTPATH}/${PASSPHRASE_FILENAME}

## check that file exists
if [ ! -f ${PASSPHRASE_FILE_FULL_PATH} ]; then
    printf "\033[1;31mPassphrase file \"${PASSPHRASE_FILE_FULL_PATH}\" does not exist! Exiting.\033[0m\n"
    exit 1;
else
    ## check ownership
    if [ ! -O ${PASSPHRASE_FILE_FULL_PATH} ]; then
        printf "\033[1;31mPassphrase file is not owned by this user. Exiting.\033[0m\n"
        exit 1;
    else
        ## check strict permissions (600)
        if [ $(stat -c %a ${PASSPHRASE_FILE_FULL_PATH}) != 600 ]; then
            printf "\033[1;31mPassphrase file has wrong file permissions. Please set to 600. Exiting.\033[0m\n"
            exit 1;
        else
            ## check that file has exactly one line
            if [ $(cat ${PASSPHRASE_FILE_FULL_PATH} | wc -l) != 1 ]; then
                printf "\033[1;31mPassphrase file does not contain exactly one single line. Exiting.\033[0m\n"
            fi # // lines
        fi # // permissions
    fi # // ownership
fi # // exists


printf "\033[1;32mPassphrase file looks ok: ${PASSPHRASE_FILE_FULL_PATH}\033[0m\n"


# remove .gpg suffix
VM_TAR_FILE="$1"
VM_DIR=${1%.gpg}

if [ -d ${VM_DIR} ]; then
    printf "\033[1;31mError! Target directory already exists: ${VM_DIR}\033[0m\n"
    exit 1
fi
mkdir "${VM_DIR}"

${GPG} -d --passphrase-file "${PASSPHRASE_FILE_FULL_PATH}" --no-tty --no-use-agent "${VM_TAR_FILE}" | ${TAR} x -v -S -C "${VM_DIR}"

if [ $? = 0 ]; then
    # Return 0 -> so everything was ok
    printf "\033[1;32mSuccess\033[0m\n"
else
    printf "\033[1;31mFailed!\033[0m\n"
    printf "\033[1;31mPlease check messages above. Most commenly: Wrong Passphrase or Disc Full.\033[0m\n"
fi

printf "Extracted: \033[1;33m$(du -sh "${VM_DIR}")\033[0m\n"

endTimer
#EOF
