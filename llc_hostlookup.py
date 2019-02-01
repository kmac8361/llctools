from maas.client import login
import sys

client = login(
    "http://localhost:5240/MAAS/",
    username="admin", password="admin",
)

matchAll = False
if (len(sys.argv) > 2):
    print("usage: llchost [hostname]")
    exit(1)
elif (len(sys.argv) == 2):
    hostName = sys.argv[1]
    hostName = hostName.lower()
else:
    matchAll = True

for machine in client.machines.list():
    if (matchAll == True) or (machine.hostname.lower().find(hostName) != -1) :    
        print("----------------------------------------")
        print("Hostname:   ",machine.hostname)
        print("IPAddress:  ",machine.ip_addresses)
        print("Status:     ",machine.status_name)
        print("OS:         ",machine.osystem)
        print("DistSeries: ",machine.distro_series)
        print("CPUs:       ",machine.cpus)
        print("Arch:       ",machine.architecture)
        print("Tags:       ",machine.tags)
        #print("Owner:      ",machine.owner)
        print("CPUs:       ",machine.cpus)
        print("Memory:     ",machine.memory)
        print("HWE Kernel: ",machine.hwe_kernel)
        print("SystemId:   ",machine.system_id)
        powerParams = machine.get_power_parameters()
        print("PowerAddr:  ", powerParams['power_address'])
        print("PowerState: ",machine.power_state)
        print("PowerType:  ",machine.power_type)
        print("Zone: ",machine.zone)
        print("Interfaces: ")
        for iface in machine._data['interface_set']:
            print("  Name: ", iface['name'], "  MACAddr: ", iface['mac_address'])
            #if iface['vlan']:
            #    print("  Fabric: ", iface['vlan']['fabric'])
            #    print("  VLAN: ", iface['vlan']['name'])
exit(0)
