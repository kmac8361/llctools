#!/bin/bash
echo "**** Checking iperf3 is running....  $(date '+%Y-%m-%d %H:%M:%S')  ****"
activePID=`/usr/bin/pgrep -x iperf3`
if [[ "$activePID" == "" ]]
then
    echo "**** Starting iperf3 server....   $(date '+%Y-%m-%d %H:%M:%S') ****"
    nohup iperf3 -s &
    sleep 2
    newPID=`/usr/bin/pgrep -x iperf3`
    if [[ "$newPID" != "" ]]
    then
        echo "**** Status: Restarted and running. PID: $newPID"
    else
        echo "**** Status: Failed to restart... Will reattempt next cycle ****"
    fi
else
    echo "**** Status: Running. PID: $activePID"
fi

exit 0
