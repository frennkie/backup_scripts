#!/bin/bash
#
# Name:	 	backup-zip.sh
# Description:	Take given folder and create an encrypted tar archive
#
# Author:	mail@rhab.de
# Version:	0.5

#set -x


PASSPHRASE="geheim"


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

# make sure there is no trailing / 
VM_DIR=$(echo "$1" | ${SED} 's#/*$##')

echo "${VM_DIR}"

${TAR} c -v -S -C "${VM_DIR}" . | ${GPG} -c --passphrase "${PASSPHRASE}" --cipher-algo aes256 --compress-algo zlib --no-use-agent --batch --no-tty --yes -o "${VM_DIR}".gpg

if [[ $? == 0 ]]; then
    # Return 0 -> so everything was ok
    echo -e "\e[32mSuccess\e[0m"
else
    echo -e "\e[31mFailed\e[0m"
fi

echo -e "Resulting File: \e[33m$(ls -sh "${VM_DIR}".gpg)\e[0m"

endTimer
#EOF
