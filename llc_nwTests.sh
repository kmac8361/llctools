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

# +++++ Network Test 4: ETH stats check from MaaS  node +++++
echo -e "\n*** ETH stats check from MaaS Node ***"
rx_packets=$(ethtool -S eno1 | grep rx_packets | awk '{print $2}')
rx_errors=$(ethtool -S eno1 | grep rx_errors | awk '{print $2}')
rx_crc_errors=$(ethtool -S eno1 | grep rx_crc_errors | awk '{print $2}')
rx_frame_errors=$(ethtool -S eno1 | grep rx_frame_errors | awk '{print $2}')
collisions=$(ethtool -S eno1 | grep collisions | awk '{print $2}')
tx_packets=$(ethtool -S eno1 | grep tx_packets | awk '{print $2}')
tx_errors=$(ethtool -S eno1 | grep tx_errors | awk '{print $2}')
tx_dropped=$(ethtool -S eno1 | grep tx_dropped | awk '{print $2}')

thresh=0.50
rx_err_rate=$(echo "scale=4 ; $rx_errors / $rx_packets * 100" | bc)
echo "RX Error Rate: $rx_err_rate"
result=$(echo "$rx_err_rate > $thresh" |bc -l)
if [ $result -eq 1 ]
then
    alarmMsg="ALARM - RX Error Rate ($rx_err_rate) exceeded threshold $thresh. RX Packets($rx_packets) RX Errors($rx_errors)"
    echo $alarmMsg
    mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
fi

rx_crc_err_rate=$(echo "scale=4 ; $rx_crc_errors / $rx_packets * 100" | bc)
echo "RX CRC Error Rate: $rx_crc_err_rate"
result=$(echo "$rx_crc_err_rate > $thresh" |bc -l)
if [ $result -eq 1 ]
then
    alarmMsg="ALARM - RX CRC Error Rate ($rx_crc_err_rate) exceeded threshold $thresh. RX Packets($rx_packets) RX CRC Errors($rx_crc_errors)"
    echo $alarmMsg
    mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
fi

rx_frame_err_rate=$(echo "scale=4 ; $rx_frame_errors / $rx_packets * 100" | bc)
echo "RX FRAME Error Rate: $rx_frame_err_rate"
result=$(echo "$rx_frame_err_rate > $thresh" |bc -l)
if [ $result -eq 1 ]
then
    alarmMsg="ALARM - RX FRAME Error Rate ($rx_frame_err_rate) exceeded threshold $thresh. RX Packets($rx_packets) RX Frame Errors($rx_frame_errors)"
    echo $alarmMsg
    mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
fi

tx_err_rate=$(echo "scale=4 ; $tx_errors / $tx_packets * 100" | bc)
echo "TX Error Rate: $tx_err_rate"
result=$(echo "$tx_err_rate > $thresh" |bc -l)
if [ $result -eq 1 ]
then
    alarmMsg="ALARM - TX Error Rate ($tx_err_rate) exceeded threshold $thresh. TX Packets($tx_packets) TX Errors($tx_errors)"
    echo $alarmMsg
    mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
fi

tx_drop_rate=$(echo "scale=4 ; $tx_dropped / $tx_packets * 100" | bc)
echo "TX Drop Rate: $tx_drop_rate"
result=$(echo "$tx_drop_rate > $thresh" |bc -l)
if [ $result -eq 1 ]
then
    alarmMsg="ALARM - TX Drop Rate ($tx_drop_rate) exceeded threshold $thresh. TX Packets($tx_packets) TX Dropped($tx_dropped)"
    echo $alarmMsg
    mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
fi

collision_rate=$(echo "scale=4 ; $collisions / $tx_packets * 100" | bc)
echo "Collision Rate: $collision_rate"
result=$(echo "$collision_rate > $thresh" |bc -l)
if [ $result -eq 1 ]
then
    alarmMsg="ALARM - Collision Rate ($collision_rate) exceeded threshold $thresh. TX Packets($tx_packets) Collisions($collisions)"
    echo $alarmMsg
    mail -s "$localHost: $alarmMsg" $alarmRecipentList < /dev/null >& /dev/null
fi

# +++++ Network Test 5: ARP table check on router +++++
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

