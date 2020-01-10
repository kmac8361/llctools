#!/bin/bash
# llc_dailyReport.sh

# If user is not root then exit
# if [ "$(id -u)" != "0" ]; then
#   echo "Must be run with sudo or by root"
#   exit 77
# fi

localPid=$$
localHost=`hostname`
alarmRecipentList="Kurt.McIntyre1@verizon.com"

echo "****  $localHost : $(date '+%Y-%m-%d %H:%M:%S') - Starting llc_dailyReport....  ****"

echo -e "\n*** Uptime Check ***"
uptime
echo -e "\n*** List system boots ***"
journalctl --list-boots

# +++++ Alarm Check 1: Check critical services are running +++++
echo -e "\n*** Service Status Check ***"
echo "Key services check..."
srvcCheckList="maas-rackd maas-regiond maas-dhcpd maas-proxy rsyslog cron"
for srvc in $srvcCheckList; do
    astate=`systemctl show -p ActiveState $srvc`
    sstate=`systemctl show -p SubState $srvc`
    echo -e "Service: $srvc \t$astate \t$sstate"
    if [[ "$astate" != "ActiveState=active" ]]; then
	alarmMsg="ALARM - Critical Service Failure. Service: $srvc \t$astate \t$sstate"
	echo $alarmMsg
	mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
    fi
done

echo -e "\nFailed units check..."
failedUnits=`systemctl list-units --state=failed --no-legend | awk '{print $1}'`
if [[ "$failedUnits" != "" ]]; then
    alarmMsg="ALARM - Failed Service Units: $failedUnits"
    echo $alarmMsg
    mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
else
    echo "Healthy: No failed units"
fi

# +++++ Alarm Check 2: Verify MaaS and Juju backups are being created  +++++
echo -e "\n*** MaaS and Juju Backup Listing ***"

MAASBCKROOT=/var/backups/maas
JUJUBCKROOT=/var/backups/juju
echo $MAASBCKROOT
ls -l $MAASBCKROOT
echo -e "\n$JUJUBCKROOT"
ls -l $JUJUBCKROOT

# Now check that backups have been created in last 24 hours.
for subdir in maas juju
do
    BCKROOT=/var/backups/${subdir}
    if [[ ! -d $BCKROOT ]]
    then
	alarmMsg="ALARM: Backup dir <${BCKROOT}> does not exist, exiting..."
        echo $alarmMsg
	mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
        break
    fi

    cd ${BCKROOT}
    rc=$?
    if [[ $rc != 0 ]]
    then
	alarmMsg="ALARM: Could not change dir to ${BCKROOT} exiting..."
        echo $alarmMsg
	mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
        break
    fi

    # Get backup filename created in last day
    backupFile=`find . -maxdepth 1 -type f -name "${subdir}*backup*.tgz" -ctime -1 -exec ls {} \;`
    if [[ "$backupFile" == "" ]]; then
        alarmMsg="ALARM: ${subdir} backup was not created in last day"    
        echo $alarmMsg
        mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
    fi
done

# +++++ Alarm Check 3: Verify IPerf is running on MaaS server  +++++
echo -e "\n*** IPerf3 Status Checking ***"
activePID=`/usr/bin/pgrep -x iperf3`
if [[ "$activePID" == "" ]]; then
    echo "IPerf3 Status: Not Running. Sleep 60 seconds and retest..."
    sleep 60
    activePID=`/usr/bin/pgrep -x iperf3`
    if [[ "$activePID" == "" ]]; then
        alarmMsg="ALARM: IPerf3 Not Running."
        echo $alarmMsg
        mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
    fi
else
    echo "IPerf3 Status: Running. PID: $activePID"
fi

echo -e "\n*** Disk Usage Check ***"
df -h

# +++++ Alarm Check 4: Check against High Disk Usage on MaaS server  +++++
# Report alarm for any disk filesystem running at 70% plus capacity
df -h --output=source,size,used,pcent | grep -v Use | sed s/%// | while read output;
do
    filesys=$(echo $output | awk '{print $1}')
    dfsize=$(echo $output | awk '{print $2}')
    dfused=$(echo $output | awk '{print $3}')
    dfpcent=$(echo $output | awk '{print $4}')
    if [[ $dfpcent -ge 70 ]]; then
	alarmMsg="ALARM: Disk filesystem $filesys is running low on space. Size: $dfsize Used: $dfused Percent: $dfpcent"
        echo $alarmMsg
        mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
    fi
done

echo -e "\n*** CPU/Memory Usage Check ***"
# Run in batch mode to remove escape sequence characters
top -b -n 1

# +++++ Alarm Check 5: Check High Overall CPU Usage on MaaS server  +++++
cpuUsage=`grep 'cpu ' /proc/stat | awk '{cpu_usage=($2+$4)*100/($2+$4+$5)} END {print cpu_usage "%"}'`
wholeCpu=${cpuUsage%.*}
if [[ $wholeCpu -ge 60 ]]; then
    alarmMsg="ALARM: Overall CPU usage high - $wholeCpu"
    echo $alarmMsg
    mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
fi

# +++++ Alarm Check 6: Check High Overall RAM Usage on MaaS server  +++++
ramUsage=`free -m | awk '/Mem:/ { printf("%3.0f", $3/$2*100) }'`
if [[ $ramUsage -ge 80 ]]; then
    alarmMsg="ALARM: Overall RAM usage high - $ramUsage"
    echo $alarmMsg
    mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
fi

# +++++ Alarm Check 7: Check High Single Process CPU Usage on MaaS server  +++++
# Following will examine top 5 cpu processes and flag anyone running over 35 percent cpu
ps -Ao user,comm,pid,pcpu --sort=-pcpu --no-headers | head -n 5 | while read output;
do
    usrName=$(echo $output | awk '{print $1}')
    cmdName=$(echo $output | awk '{print $2}')
    pidVal=$(echo $output | awk '{print $3}')
    cpuUsage=$(echo $output | awk '{print $4}')
    wholeCpu=${cpuUsage%.*}
    if [[ $wholeCpu -ge 35 ]]; then
	alarmMsg="ALARM: Process $cmdName by $usrName and pid $pidVal is executing at high cpu $cpuUsage."
	echo $alarmMsg
	mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
    fi
done

echo -e "\n*** Virsh Listing ***"
virsh list --all

echo -e "\n*** Cron Listing ***"
echo -e "\nubuntu crontab..."
crontab -l | grep -v '^#'
echo "root crontab..."
sudo crontab -l -u root | grep -v '^#'

echo -e "\n*** MaaS Machine State Listing ***"
python3.6 /srv/python-libmaas/llc_hostlookup.py

# Dump Juju model listing
echo -e "\n*** Juju Model Status Check ***"
juju list-models

# Dump detailed status of each Juju model
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

# NOTE: No VM snapshots are currently executed on MaaS server at present time
# echo -e "\n*** Snapshot Listing ***"

# +++++ Alarm Check 8: Check system crash file  +++++
# Check /var/crash in last 24 hours
# cat /proc/cmdline
echo -e "\n*** Check for any system crash of MaaS server ***"
cd /var/crash
crashFile=`find . -maxdepth 1 -type f -name "*.crash" -ctime -1 -exec ls {} \;`
if [[ "$crashFile" != "" ]]; then
    alarmMsg="ALARM: New crash file(s) was created in last day in /var/crash."    
    echo $alarmMsg
    mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
fi

echo -e "\n*** Report System Logs Disk Usage ***"
journalctl --disk-usage

# +++++ Alarm Check 9: Check alerts and critical logs or error messages  +++++
echo -e "\n*** Alert Logs Search ***"
jrnalert=`journalctl --since yesterday -p alert --quiet`
if [[ "$jrnalert" != "" ]]; then
    alarmMsg="ALARM: Log alerts generated in last day. Login and check messages"
    echo $alarmMsg
    mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
    journalctl --since yesterday -p alert
else
    echo "INFO: No log alerts in last day"
fi

echo -e "\n*** Critical Logs Search ***"
jrncrit=`journalctl --since yesterday -p crit --quiet`
if [[ "$jrncrit" != "" ]]; then
    alarmMsg="ALARM: Critical logs generated in last day. Login and check messages"
    echo $alarmMsg
    mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
    journalctl --since yesterday -p crit
else
    echo "INFO: No critical logs in last day"
fi

echo -e "\n*** Search Predefined Error Messages in Logs***"
# +++++ Alarm Check 10: Check for prefined error message strings  +++++
tmperr=/tmp/jrnerrs.$localPid
journalctl --since yesterday -p err >& $tmperr
ErrMsgList=('faulty module'
            'internal error' 
            'pci driver initialization failed'
            'bad address'
            'bad file number'
            'bad module'
            'bad trap'
            'no buffer space available'
            'no such device'
            'error for command'
            'no space left on device'
            'exec format error'
            'file table overflow'
            'file too large'
            'illegal instruction'
            'io error'
            'i/o error'
            'input/output error'
            'kernel read error'
            'too many open files'
            'panic'
            'memory error'
            'memory leak'
            'out of memory'
            'time sync error'
            'swap space limit'
            'media error'
            'fatal error'
            'correctable memory error'
            'uncorrectable memory error'
            'pci bus error'
            'disk not responding'
            'parity error'
            'trying to be our address'
            'run fsck'
            'cpu clock throttled'
            'ecc error'
            'eth0 bad'
            'eth1 bad'
     )
for errmsg in "${ErrMsgList[@]}"; 
do
    errstr=`grep -i "$errmsg" $tmperr`
    if [[ "$errstr" != "" ]]; then
       alarmMsg="ALARM: Predefined error string($errmsg) found in system logs"
       echo $alarmMsg
       # Comment out email since many are occuring now
       #mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
       grep -i "$errmsg" $tmperr | head -n 5
    fi
done
rm -f $tmperr

echo -e "\n*** Check failed password logins on system ***"
# +++++ Alarm Check 11: Check system for failed password logins  +++++
# Check authentication/password failure logs
failedLogins=`journalctl _COMM=sshd --since yesterday | grep -i "Failed password" | wc -l`
if [[ $failedLogins -ge 3 ]]; then
    alarmMsg="ALARM: Failed password logins($failedLogins) exceeded threshold"
    echo $alarmMsg
    mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
    journalctl _COMM=sshd --since yesterday | grep -i "Failed password"
else
    echo -e "Failed password login attempts($failedLogins) under limit"
fi

alarmMsg="INFO: Completed Daily Report Script - $(date '+%Y-%m-%d %H:%M:%S')"
mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null

echo -e "\n**** $localHost : $(date '+%Y-%m-%d %H:%M:%S') - Completed llc_dailyReport.  ****"

exit 0

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Below commands just saved for future reference....

# String length & subtraction
#   mlen=${#model}
#   lastidx=$(($mlen - 1))

# Following will print output like this:  4.51939%
# grep 'cpu ' /proc/stat | awk '{cpu_usage=($2+$4)*100/($2+$4+$5)} END {print cpu_usage "%"}'

# Following will print output like this: CPU 4.7% RAM 23.2% HDD 38%
# echo "CPU `LC_ALL=C top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}'`% RAM `free -m | awk '/Mem:/ { printf("%3.1f%%", $3/$2*100) }'` HDD `df -h / | awk '/\// {print $(NF-1)}'`"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

