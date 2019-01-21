#!/bin/bash
echo "Starting llc_jujuBackup...."

BCKROOT=/var/backups/juju
mkdir -p $BCKROOT
if [[ ! -d $BCKROOT ]]
then
    echo "ERROR: Backup dir <${BCKROOT}> does not exist, exiting..."
    exit 1
fi

cd /home/ubuntu
rc=$?
if [[ $rc != 0 ]]
then
    echo "ERROR: Could not change dir to ubuntu home. exiting..."
    exit 1
fi

echo "Starting juju client backup...."
clientBackup="juju_client_backup_$(date '+%Y%m%d_%H%M%S').tgz"
sudo -u ubuntu tar -cvpzf $clientBackup /home/ubuntu/.local/share/juju
sudo mv $clientBackup $BCKROOT
echo "Completed juju client backup...."

echo "Starting juju controller backup...."
activeModel=`sudo -u ubuntu juju show-model | awk '{print $1 $2}' | grep 'short-name' | cut -c 12-`
sudo -u ubuntu juju switch controller
ctrllrBackup="juju_ctrller_backup_$(date '+%Y%m%d_%H%M%S').tgz"
sudo -u ubuntu juju create-backup --filename=$ctrllrBackup
sudo mv $ctrllrBackup $BCKROOT

if [[ "$activeModel" != "" ]]
then
    sudo -u ubuntu juju switch $activeModel
else
    sudo -u ubuntu juju switch default
fi

echo "Completed juju controller backup...."

echo "Completed llc_jujuBackup...."

exit 0
