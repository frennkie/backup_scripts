#!/bin/bash
#
# Name:	 	backup-zip.sh
# Description:	Take given folder ($1) and create an encrypted tar archive
#
# Author:	mail@rhab.de
# Version:	0.6

## Debuging
set -x

## Put the passphrase for the symmetric gpg encryption into this file
## file is expected to be located in same directory as backup-[un]zip.sh script
## file needs to owned by same user (I think root) and needs permissions "600"
## passphrase goes into first line (no other content)
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
    if [[ ${DURATION} -le 60 ]] ; then
        echo "Ended: "${END_TIME}" - Duration: ${DURATION} Seconds"
    else
        echo "Ended: "${END_TIME}" - Duration: $(awk 'BEGIN{ printf "%.2f\n", '${DURATION}'/60}') Minutes"
    fi
}

startTimer

## setup full patch for passphrase file and check it
SCRIPTPATH=$(dirname $0)
PASSPHRASE_FILE_FULL_PATH=${SCRIPTPATH}/${PASSPHRASE_FILENAME}

## check that file exists
if [[ ! -f ${PASSPHRASE_FILE_FULL_PATH} ]]; then
    echo -e "\e[31mPassphrase file does not exist! Exiting.\e[0m"
    exit 1;
else 
    ## check ownership
    if [[ ! -O ${PASSPHRASE_FILE_FULL_PATH} ]]; then
        echo -e "\e[31mPassphrase file is not owned by me (should be root?!). Exiting.\e[0m"
        exit 1;	
    else
        ## check strict permissions (600)
	if [ $(stat -c %a ${PASSPHRASE_FILE_FULL_PATH}) != 600 ]; then
	    echo -e "\e[31mPassphrase file has wrong file permissions. Please set to 600. Exiting.\e[0m"
	    exit 1;
	else
            ## check that file has exactly one line
	    if [ $(cat ${PASSPHRASE_FILE_FULL_PATH} | wc -l) != 1 ]; then
	        echo -e "\e[31mPassphrase file does not contain exactly one single line. Exiting.\e[0m"
  	    fi # // lines
	fi # // permissions
    fi # // ownership
fi # // exists


echo -e "\e[32mPassphrase file looks ok.\e[0m"

# make sure there is no trailing / 
VM_DIR=$(echo "$1" | ${SED} 's#/*$##')

echo "${VM_DIR}"

${TAR} c -v -S -C "${VM_DIR}" . | ${GPG} -c --passphrase-file "${PASSPHRASE_FILE_FULL_PATH}" --cipher-algo aes256 --compress-algo zlib --no-use-agent --batch --no-tty --yes -o "${VM_DIR}".gpg

if [[ $? == 0 ]]; then
    # Return 0 -> so everything was ok
    echo -e "\e[32mSuccess\e[0m"
else
    echo -e "\e[31mFailed\e[0m"
fi

echo -e "Resulting File: \e[33m$(ls -sh "${VM_DIR}".gpg)\e[0m"

endTimer
#EOF
