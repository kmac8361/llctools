from maas.client import login
import sys

def dump(obj):
  for attr in dir(obj):
    print("obj.%s = %r" % (attr, getattr(obj, attr)))

def dumpNested(obj, nested_level=0):
    spacing = '   '
    if type(obj) == dict:
        print('%s{' % ((nested_level) * spacing))
        for k, v in obj.items():
            if hasattr(v, '__iter__'):
                print('%s%s:' % ((nested_level + 1) * spacing, k))
                dumpNested(v, nested_level + 1)
            else:
                print('%s%s: %s' % ((nested_level + 1) * spacing, k, v))
        print('%s}' % (nested_level * spacing))
    elif type(obj) == list:
        print('%s[' % ((nested_level) * spacing))
        for v in obj:
            if hasattr(v, '__iter__'):
                dumpNested(v, nested_level + 1)
            else:
                print('%s%s' % ((nested_level + 1) * spacing, v))
        print('%s]' % ((nested_level) * spacing))
    else:
        print('%s%s' % (nested_level * spacing, obj))

client = login(
    "http://localhost:5240/MAAS/",
    username="admin", password="admin",
)
tmpl = "{0.hostname} {1.name} {1.mac_address}"
for machine in client.machines.list():
    for interface in machine.interfaces:
        print(tmpl.format(machine, interface))
print("\nMachine python dir listing...")
print(dir(machine))

#print("\nDumping machine object...")
#dump(machine)

print("\nDumping machine data...")
dumpNested(machine._data)

print("\nDumping key machine attrs...")
print("Hostname: ",machine.hostname)
print("Status: ",machine.status_name)
print("OS: ",machine.osystem)
print("CPUs: ",machine.cpus)
print("Arch: ",machine.architecture)
print("Tags: ",machine.tags)
print("Owner: ",machine.owner)
print("OS: ",machine.osystem)
print("CPUs: ",machine.cpus)
print("Memory: ",machine.memory)
print("IPAddresses: ",machine.ip_addresses)
print("HWE Kernel: ",machine.hwe_kernel)
print("SystemId: ",machine.system_id)
print("DistroSeries: ",machine.distro_series)
print("PowerState: ",machine.power_state)
print("PowerType: ",machine.power_type)
print("Zone: ",machine.zone)
print("Interfaces: ")
for iface in machine._data['interface_set']:
    print("  Name: ", iface['name'])
    print("  Fabric: ", iface['vlan']['fabric'])
    print("  VLAN: ", iface['vlan']['name'])
    print("  MACAddr: ", iface['mac_address'])
#print("xxx",machine.xxx)
#print("xxx",machine.xxx)
#print("xxx",machine.xxx)
#print("xxx",machine.xxx)
#print("xxx",machine.xxx)
#print("xxx",machine.xxx)
#print("xxx",machine.xxx)
#print("xxx",machine.xxx)
#print("xxx",machine.xxx)

