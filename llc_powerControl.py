#!/usr/bin/python3.6
from maas.client import login
from maas.client.enum import PowerState
import os
import sys
import socket, struct, fcntl
import time

# First, verify sudo privilege
if (os.geteuid() != 0):
    print("ERROR: You need to have sudo root privileges to execute this script")
    exit(1)

llcHostname = socket.gethostname()
if (not llcHostname):
    print("ERROR: Unable to get local LLC hostname.")
    exit(1)

#print("Local hostname: ",llcHostname)
llcNumber = llcHostname[9:]
#print("LLC Number: ",llcNumber)
maasPwd = "maas" + llcNumber

# Next verify command usage
allNodePowerCycle = False
printUsage = False
if (len(sys.argv) == 3):
    hostName = sys.argv[2]
    powerCmd = sys.argv[1].lower()
    hostName = hostName.lower()

    if (powerCmd == "off") or (powerCmd == "on"):
        if (hostName == "full"):
            allNodePowerCycle = True
    else:
        printUsage = True
else:
    printUsage = True
        
if (printUsage):
    print("usage: llc_powerControl.py [ on | off ] [hostname | full ]")
    exit(1)

# Need local IP because we local virsh must be cycled last for 'off' and first for 'on'
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sockfd = sock.fileno()
SIOCGIFADDR = 0x8915

def get_ip(iface = 'eth0'):
    ifreq = struct.pack('16sH14s', iface.encode('utf-8'), socket.AF_INET, b'\x00'*14)
    try:
        res = fcntl.ioctl(sockfd, SIOCGIFADDR, ifreq)
    except:
        return None
    ip = struct.unpack('16sH2x4s8x', res)[2]
    return socket.inet_ntoa(ip)
 
localIP = get_ip('br0')
if (not localIP):
    print("ERROR: Unable to get local IP address from local MaaS server. Check br0 interface exists with ifconfig -a")
    exit(1)
    
client = login(
    "http://localhost:5240/MAAS/",
    username="admin", password=maasPwd,
)

# First pass we get names of all machines matching request
physMachinesToCycle = []
maasVirshToCycle = []
virshMachinesToCycle = []
for machine in client.machines.list():
    if (allNodePowerCycle == True) or (machine.hostname.lower().find(hostName) != -1) :
        # Check unknown power state
        if (machine.power_state == PowerState.UNKNOWN):
            print("INFO: Machine is in UNKNOWN power state: ", machine.hostname, ". Skiping node...")
            continue
                                                      
        # Check if node current power state already match target power state
        if (powerCmd == "on") and (machine.power_state == PowerState.ON):
            print("INFO: Machine is already in target ON power state: ", machine.hostname)
            continue
        
        if (powerCmd == "off") and (machine.power_state == PowerState.OFF):
            print("INFO: Machine is already in target OFF power state: ", machine.hostname)
            continue
        
        powerParams = machine.get_power_parameters()
        if (not powerParams) or (not powerParams['power_address']):
            print("INFO: Cannot obtain power address for machine: ", machine.hostname, ". Skipping node...")
            continue
            
        if (machine.power_type == "virsh"):
            start = powerParams['power_address'].find('ubuntu@')
            end   = powerParams['power_address'].find('/system',start+7)
            if (start == -1) or (end == -1):
                print("ERROR: Unable to get power address from virsh machine: ",machine.hostname)
                print("       Power address string: ",powerParams['power_address'])
                exit(1)
            powerIP = powerParams['power_address'][start+7:end]
            if (powerIP == localIP):
                maasVirshToCycle.append(machine.hostname)
                print("INFO: Added local MAAS virsh node to powercycle list: ", machine.hostname)
            else:
                virshMachinesToCycle.append(machine.hostname)
                print("INFO: Added virtual node to powercycle list: ", machine.hostname)
        else:
            physMachinesToCycle.append(machine.hostname)
            print("INFO: Added physical machine node to powercycle list: ", machine.hostname)

if (not physMachinesToCycle) and (not maasVirshToCycle) and (not virshMachinesToCycle):
    print("No matching machines found for PowerCycle...")
    exit(1)

# Get user confirmation
if (physMachinesToCycle):
    print("The following physical machines will be powered: ", powerCmd)
    for machineName in physMachinesToCycle:
        print("    ",machineName)

if (virshMachinesToCycle):
    print("The following virtual machines will be powered: ", powerCmd)
    for machineName in virshMachinesToCycle:
        print("    ",machineName)

if (maasVirshToCycle):
    print("The following local MaaS virsh machines will be powered: ", powerCmd)
    for machineName in maasVirshToCycle:
        print("    ",machineName)

answer = input("Please confirm (y or n) the operation: ")
if (answer.lower() != "y"):
    print("Operation cancelled. Exiting...")
    exit(1)

# Second pass. If target is ON state, do local MaaS virsh machines first.  If target is OFF, do remote virtual machines.
if (powerCmd == "on") and maasVirshToCycle:
    for machine in client.machines.list():
        if (machine.hostname in maasVirshToCycle):
            print("INFO: Powering on local MaaS virsh machine: ", machine.hostname)
            #machine.power_on()
    print("INFO: Sleeping 30 seconds to allow local MaaS virsh machines to startup...")
    #time.sleep(30)
elif (powerCmd == "off") and virshMachinesToCycle:
    for machine in client.machines.list():
        if (machine.hostname in virshMachinesToCycle):
            print("INFO: Powering off remote virtual machine: ", machine.hostname)
            #machine.power_off()
    print("INFO: Sleeping 15 seconds to allow remote virtual machines to power down...")
    #time.sleep(15)

# Third pass. If target is ON state, do physical machines next.  If target is OFF, also do physical machines machines.
if (powerCmd == "on") and physMachinesToCycle:
    for machine in client.machines.list():
        if (machine.hostname in physMachinesToCycle):
            print("INFO: Powering on physical machine: ", machine.hostname)
            #machine.power_on()
    print("INFO: Sleeping 60 seconds to allow physical machines to startup...")
    #time.sleep(60)
elif (powerCmd == "off") and physMachinesToCycle:
    for machine in client.machines.list():
        if (machine.hostname in physMachinesToCycle):
            print("INFO: Powering off physical machine: ", machine.hostname)
            #machine.power_off()
    print("INFO: Sleeping 30 seconds to allow physical machines to power down...")
    #time.sleep(30)

# Fourth pass. If target is ON state, do remote virtual machines next.  If target is OFF, do local MaaS virsh machines next..
if (powerCmd == "on") and virshMachinesToCycle:
    for machine in client.machines.list():
        if (machine.hostname in virshMachinesToCycle):
            print("INFO: Powering on remote virtual machine: ", machine.hostname)
            #machine.power_on()
    print("INFO: Sleeping 30 seconds to allow remote virtual machines to power on...")
    #time.sleep(30)
elif (powerCmd == "off") and maasVirshToCycle:
    for machine in client.machines.list():
        if (machine.hostname in maasVirshToCycle):
            print("INFO: Powering off local MaaS virsh machine: ", machine.hostname)
            #machine.power_off()
    print("INFO: Sleeping 15 seconds to allow local MaaS virsh machines to power down...")
    #time.sleep(15)

# Last pass. Iterate over all machines involved in power cycle and query their power state.
print("******************  Final PowerCycle State Results *********************")
for machine in client.machines.list():
    if (machine.hostname in virshMachinesToCycle) or (machine.hostname in maasVirshToCycle) or (machine.hostname in physMachinesToCycle):
        print("INFO: Final power state for machine: ", machine.hostname, " = ", machine.query_power_state())

if (allNodePowerCycle and (powerCmd == "off")):
    print("INFO: Sleeping 15 seconds prior to local MaaS shutdown...")
    #time.sleep(15)
    #os.system("sudo shutdown -h now")
    
exit(0)
