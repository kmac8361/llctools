#!/bin/bash
echo "\n****  $(date '+%Y-%m-%d %H:%M:%S') - Starting llc_maasBackup....  ****"

BCKROOT=/var/backups/maas
mkdir -p $BCKROOT
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

sudo -u postgres /usr/bin/pg_dumpall -c > postgres.sql

if [[ ! -f postgres.sql ]]
then
    echo "ERROR: Postgres SQL was not created successfully. exiting..."
    exit 1
fi

MAASBACKUP=maas_backup_$(date "+%Y%m%d_%H%M%S").tgz
sudo tar -cvpzf $MAASBACKUP /etc/maas /var/lib/maas/maas-proxy.conf /var/lib/maas/dhcpd.conf /srv/mec /srv/llctools /srv/smicro-config postgres.sql 

sudo rm -f postgres.sql

DAYNUM=$(date "+%d")
if [[ "$DAYNUM" == "01" ]]
then
    echo "INFO: Saving MAAS monthly backup..."
    cp $MAASBACKUP ${BCKROOT}/monthly

    cd ${BCKROOT}/monthly

    echo "INFO: Find and remove monthly MAAS backups older than 45 days..."
    # Remove backup archives files older then 45 days 
    find . -maxdepth 1 -type f -name "maas*backup*20*" -mtime +45 -exec ls -ld {} \;
    find . -maxdepth 1 -type f -name "maas*backup*20*" -mtime +45 -exec rm -fr {} \;
fi

echo "**** $(date '+%Y-%m-%d %H:%M:%S') - Completed llc_maasBackup.  ****"

exit 0
