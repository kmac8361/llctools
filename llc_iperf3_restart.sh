#!/bin/bash
echo "**** Restarting iperf3 ....  $(date '+%Y-%m-%d %H:%M:%S')  ****"
activePID=`/usr/bin/pgrep -x iperf3`
if [[ "$activePID" == "" ]]
then
    echo "**** iperf3 server. not running...   $(date '+%Y-%m-%d %H:%M:%S') ****"
else
    echo "**** Status: Running. PID: $activePID"
    pkill iperf3
    echo "**** iperf3 server killed...   $(date '+%Y-%m-%d %H:%M:%S') ****"
fi
 
exit 0
