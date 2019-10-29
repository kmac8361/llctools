#!/bin/bash
# llc_dailyReport.sh

# If user is not root then exit
# if [ "$(id -u)" != "0" ]; then
#   echo "Must be run with sudo or by root"
#   exit 77
# fi

echo "****  $(date '+%Y-%m-%d %H:%M:%S') - Starting llc_dailyReport....  ****"

echo -e "\n*** Service Status Check ***"
echo "Key services check..."
srvcCheckList="maas-rackd maas-regiond maas-dhcpd maas-proxy rsyslog cron"
for srvc in $srvcCheckList; do
    astate=`systemctl show -p ActiveState $srvc`
    sstate=`systemctl show -p SubState $srvc`
    echo -e "Service: $srvc \t$astate \t$sstate"
done

echo -e "\nFailed units check..."
failedUnits=`systemctl list-units --state=failed --no-legend | awk '{print $1}'`
if [[ "$failedUnits" != "" ]]
then
    echo "Failed units: $failedUnits"
else
    echo "Healthy: No failed units"
fi

echo -e "\n*** MaaS and Juju Backup Listing ***"

MAASBCKROOT=/var/backups/maas
JUJUBCKROOT=/var/backups/juju
echo $MAASBCKROOT
ls -l $MAASBCKROOT
echo -e "\n$JUJUBCKROOT"
ls -l $JUJUBCKROOT

echo -e "\n*** IPerf3 Status Checkg ***"
activePID=`/usr/bin/pgrep -x iperf3`
if [[ "$activePID" == "" ]]; then
    echo "IPerf3 Status: Not Running."
else
    echo "IPerf3 Status: Running. PID: $activePID"
fi

echo -e "\n*** Disk Usage Check ***"
df -h

echo -e "\n*** CPU/Memory Usage Check ***"
top -n 1

echo -e "\n*** Virsh Listing ***"
virsh list --all

echo -e "\n*** Cron Listing ***"
# echo "root crontab..."
# sudo crontab -l -u root
# echo -e "\nubuntu crontab..."
# sudo crontab -l -u ubuntu

echo -e "\n*** MaaS Machine State Listing ***"
python3.6 /srv/python-libmaas/llc_hostlookup.py

echo -e "\n*** Juju Model Status Check ***"
juju list-models

modelList=`juju list-models | grep admin | awk '{print $1}' | sed 's/*//'`

# Save off active model
activeModel=`juju show-model | awk '{print $1 $2}' | grep 'short-name' | cut -c 12-`
for model in $modelList; do
    if [[ "$model" == "controller" || "$model" == "default" ]]; then
       continue
    fi
    echo -e "\nModel $model detailed status"
    juju switch $model
    juju status
done
# Switch back to original active model
if [[ "$activeModel" != "" ]]
then
    juju switch $activeModel
else
    juju switch default
fi


echo -e "\n*** Snapshot Listing ***"



echo -e "\n*** Critical Logs Search ***"


exit 0



# String length & subtraction
#   mlen=${#model}
#   lastidx=$(($mlen - 1))


echo "**** $(date '+%Y-%m-%d %H:%M:%S') - Completed llc_dailyReport.  ****"

exit 0
