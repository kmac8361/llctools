#!/bin/bash
echo "Starting llc_maasBackup...."

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

sudo tar -cvpzf maas_backup_$(date "+%Y%m%d_%H%M%S").tgz /etc/maas /var/lib/maas/maas-proxy.conf /var/lib/maas/dhcpd.conf /srv/mec /srv/llctools /srv/smicro-config postgres.sql 

sudo rm -f postgres.sql

echo "Completed llc_maasBackup...."

exit 0
