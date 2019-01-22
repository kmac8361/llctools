#!/bin/bash
echo "\n****  $(date '+%Y-%m-%d %H:%M:%S') - Starting llc_jujuBackup....  ****"

BCKROOT=/var/backups/juju
if [[ ! -d $BCKROOT ]]
then
    echo "ERROR: Backup dir <${BCKROOT}> does not exist, exiting..."
    exit 1
fi

cd $BCKROOT
rc=$?
if [[ $rc != 0 ]]
then
    echo "ERROR: Could not change dir to ${BCKROOT}. exiting..."
    exit 1
fi

echo "Starting juju client backup...."
clientBackup="juju_client_backup_$(date '+%Y%m%d_%H%M%S').tgz"
tar -cvpzf $clientBackup /home/ubuntu/.local/share/juju
echo "Completed juju client backup...."

echo "Starting juju controller backup...."
activeModel=`juju show-model | awk '{print $1 $2}' | grep 'short-name' | cut -c 12-`
juju switch controller
ctrllrBackup="juju_ctrller_backup_$(date '+%Y%m%d_%H%M%S').tgz"
juju create-backup --filename=$ctrllrBackup

if [[ "$activeModel" != "" ]]
then
    juju switch $activeModel
else
    juju switch default
fi

echo "Completed juju controller backup...."

echo "**** $(date '+%Y-%m-%d %H:%M:%S') - Completed llc_jujuBackup.  ****"

exit 0
