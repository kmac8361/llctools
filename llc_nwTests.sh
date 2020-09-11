#!/bin/bash
# llc_nwTests.sh

# If user is not root then exit
# if [ "$(id -u)" != "0" ]; then
#   echo "Must be run with sudo or by root"
#   exit 77
# fi

localPid=$$
localHost=`hostname`
alarmRecipentList="Kurt.McIntyre1@verizon.com"
mecNode="172.27.200.3"
routerIP="172.27.201.254"

echo "****  $localHost : $(date '+%Y-%m-%d %H:%M:%S') - Starting llc_nwTests....  ****"

# +++++ Network Test 1: Ping test to internet from MEC node +++++
echo -e "\n*** Ping test to internet from MEC Node ***"
ssh ubuntu@$mecNode "ping -c 5 8.8.8.8" | grep "64 bytes" 
if ! [ $? -eq 0 ] 
then 
    alarmMsg="ALARM - Failed to ping internet from MEC node"
    echo $alarmMsg
    mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
else
    echo "Success: Pinged internet from MEC node"
fi

# +++++ Network Test 2: Traceroute test to internet from MEC node +++++
echo -e "\n*** Traceroute test to internet from MEC Node ***"
ssh ubuntu@$mecNode "traceroute 8.8.8.8" | grep 'dns.google'
if ! [ $? -eq 0 ] 
then 
    alarmMsg="ALARM - Failed to reach internet with traceroute from MEC node"
    echo $alarmMsg
    mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
else
    echo "Success: Traceroute to internet from MEC node"
fi

# +++++ Network Test 3: DNS test from MEC node +++++
echo -e "\n*** DNS test from MEC Node ***"
ipaddr=`ssh ubuntu@$mecNode "dig facebook.com +short" | awk '{print $1}'`
if [[ "$ipaddr" == "" ]]
then 
    alarmMsg="ALARM - DNS test from MEC node failed"
    echo $alarmMsg
    mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
else
    echo "Success: DNS test from MEC node"
fi

# +++++ Network Test 4: ARP table check on router +++++
echo -e "\n*** ARP table check on router for missing or incomplete umich route ***"
ssh root@$routerIP "arp -a" | grep umich 
if ! [ $? -eq 0 ] 
then 
    alarmMsg="ALARM - Missing umich route on LLC router"
    echo $alarmMsg
    mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
else
    ssh root@$routerIP "arp -a" | grep umich | grep incomplete 
    if [ $? -eq 0 ] 
    then 
        alarmMsg="ALARM - Incomplete umich route on LLC router"
        echo $alarmMsg
        mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
    else
        echo "Success: UMich route exists and resolves to gateway on LLC router"
    fi
fi

alarmMsg="INFO: Completed Daily Network Tests - $(date '+%Y-%m-%d %H:%M:%S')"
mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null

echo -e "\n**** $localHost : $(date '+%Y-%m-%d %H:%M:%S') - Completed llc_nwTests.  ****"

exit 0

