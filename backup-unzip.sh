#!/bin/bash
#
# Name:         backup-unzip.sh
# Description:  Take given gpg file decrypt and extract tar archive
#
# Author:       mail@rhab.de
# Version:      0.4

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

# remove a leading / if there is one
VM_TAR_FILE="$1"
VM_DIR=$(echo "$1" | ${SED} 's#.gpg$##')

mkdir "${VM_DIR}"

${GPG} -d --passphrase "${PASSPHRASE}" --no-use-agent "${VM_TAR_FILE}" | ${TAR} x -v -S -C "${VM_DIR}"

if [[ $? == 0 ]]; then
    # Return 0 -> so everything was ok
    echo -e "\e[32mSuccess\e[0m"
else
    echo -e "\e[31mFailed\e[0m"
fi 

echo -e "Extracted: \e[33m$(du -sh "${VM_DIR}")\e[0m"

endTimer
#EOF
