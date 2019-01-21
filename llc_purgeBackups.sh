#!/bin/bash
echo "Starting llc_purgeBackups...."

for subdir in maas juju
do
    BCKROOT=/var/backups/${subdir}
    if [[ ! -d $BCKROOT ]]
    then
	echo "ERROR: Backup dir <${BCKROOT}> does not exist, exiting..."
        exit 1
    fi

    cd ${BCKROOT}
    rc=$?
    if [[ $rc != 0 ]]
    then
	echo "ERROR: Could not change dir to ${BCKROOT} exiting..."
        exit 1
    fi

    echo `pwd`

    echo "Disk space in ${BCKROOT} prior to cleanup:"
    du -h $BCKROOT

    echo "$(date '+%Y-%m-%d %H:%M:%S'). Purging older backups is starting"

    # Remove backup archives files older then 3 days 
    find . -maxdepth 1 -type f -name "${subdir}*backup*201*" -mtime +4 -exec ls -ld {} \;
    find . -maxdepth 1 -type f -name "${subdir}*backup*201*" -mtime +4 -exec rm -fr {} \;
    
    echo "Disk space in ${BCKROOT} after cleanup:"
    du -h $BCKROOT
done

echo "Exiting llc_purgeBackups...."
exit 0

