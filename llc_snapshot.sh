#!/bin/bash
echo "**** Snapshot is executing....  $(date '+%Y-%m-%d %H:%M:%S')  ****"

if [ $# != 1 ]; then
  echo "usage: llc_snapshot.sh <domain>"
  exit 1
fi

domain=$1

date2stamp () {
    date --utc --date "$1" +%s
}

dateDiff (){
    case $1 in
	-s)   sec=1;      shift;;
	-m)   sec=60;     shift;;
	-h)   sec=3600;   shift;;
	-d)   sec=86400;  shift;;
	*)    sec=86400;;
    esac
    dte1=$(date2stamp $1)
    dte2=$(date2stamp $2)
    diffSec=$((dte2-dte1))
    if ((diffSec < 0)); then abs=-1; else abs=1; fi
    echo $((diffSec/sec*abs))
}

# Test purpose
#dateDiff -d "2019-07-01" "2019-07-15"

tday=$(date +"%Y-%m-%d")
#echo $tday

# First must shutdown VM.  Snapshot will not work if it has attached GPU
virsh shutdown ${domain}

# Give time to fully sync into shutdown mode
sleep 5

# Next create new snapshot
echo "Create snapshot for domain ${domain} with name ${domain}-${tday} ..."
virsh snapshot-create-as --domain ${domain} --name ${domain}-${tday} --diskspec vda --atomic

# Restart the VM. Sleep is probably not necessary.... but I wnat snapshot fully created before restart VM with any attach GPU
sleep 3
virsh start ${domain}

# Now remove old snapshots older than 7 days.  Notice only removing those in shutoff state which this script generated
virsh snapshot-list --domain ${domain} | grep shutoff | while read snapname snapdate snaptime snapsecs snapstate; do
    daysold=$(dateDiff -d $snapdate $tday)
    echo "Snapshot $snapname dated $snapdate is days old: $daysold"
    if [ $daysold -gt "7" ];then
       echo "Delete old snapshot $snapname ..."
       virsh snapshot-delete --domain ${domain} --snapshotname $snapname
    fi
done

exit 0
