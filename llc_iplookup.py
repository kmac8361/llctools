from maas.client import login
import sys
import socket

llcHostname = socket.gethostname()
if (not llcHostname):
    print("ERROR: Unable to get local LLC hostname.")
    exit(1)

#print("Local hostname: ",llcHostname)
llcNumber = llcHostname[9:]
#print("LLC Number: ",llcNumber)
maasPwd = "maas" + llcNumber

client = login(
    "http://localhost:5240/MAAS/",
    username="admin", password=maasPwd,
)

if (len(sys.argv) < 2):
    print("usage: llcip ip-address")
    exit(1)
ipaddr = sys.argv[1]

for machine in client.machines.list():
    if ipaddr in machine.ip_addresses:    
        print("Hostname:   ",machine.hostname)
        print("Status:     ",machine.status_name)
        print("OS:         ",machine.osystem)
        print("CPUs:       ",machine.cpus)
        print("Arch:       ",machine.architecture)
        print("Tags:       ",machine.tags)
        #print("Owner:      ",machine.owner)
        print("CPUs:       ",machine.cpus)
        print("Memory:     ",machine.memory)
        #print("IPAddresses: ",machine.ip_addresses)
        print("HWE Kernel: ",machine.hwe_kernel)
        print("SystemId:   ",machine.system_id)
        print("DistSeries: ",machine.distro_series)
        print("PowerState: ",machine.power_state)
        print("PowerType:  ",machine.power_type)
        #print("Zone: ",machine.zone)
        #print("Interfaces: ")
        #for iface in machine._data['interface_set']:
        #    print("  Name: ", iface['name'])
        #    print("  Fabric: ", iface['vlan']['fabric'])
        #    print("  VLAN: ", iface['vlan']['name'])
        #    print("  MACAddr: ", iface['mac_address'])
exit(0)
