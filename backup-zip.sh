#!/bin/sh
#
# Name:            backup-zip.sh
# Description:     Take given folder ($1) and create an encrypted tar archive
#
# Author:          mail@rhab.de
# Version:         0.11

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

# remove exactly one trailing / (if there is one)
VM_DIR=${1%/}

printf "Packing up: %s to %s.gpg\n" "${VM_DIR}" "${VM_DIR}"

${TAR} c -v -S -C "${VM_DIR}" . | ${GPG} -c --passphrase-file "${PASSPHRASE_FILE_FULL_PATH}" --cipher-algo aes256 --compress-algo zlib --no-use-agent --batch --no-tty --yes -o "${VM_DIR}".gpg

if [ $? = 0 ]; then
    # Return 0 -> so everything was ok
    printf "\033[1;32mSuccess\033[0m\n"
else
    printf "\033[1;31mFailed\033[0m\n"
fi

printf "Resulting File: \033[1;33m$(ls -sh "${VM_DIR}".gpg)\033[0m\n"

endTimer
#EOF
