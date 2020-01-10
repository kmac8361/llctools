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
    print("usage: llcmodel juju-modelname")
    exit(1)
modelName = sys.argv[1]

print('{0:<30} {1:<15} {2:<15} {3:<10} {4:<15} {5:<10} {6:<15}'.format('Hostname','IpAddress','Status','OS','DistroSeries',
      'PowerType','PowerState'))
print('{0:<30} {1:<15} {2:<15} {3:<10} {4:<15} {5:<10} {6:<15}'.format('--------','---------','------','--','------------',
      '---------','----------'))
for machine in client.machines.list():
    if modelName in machine.tags:    
        print('{0:<30} {1:<15} {2:<15} {3:<10} {4:<15} {5:<10} {6:<15}'.format(machine.hostname,machine.ip_addresses[0],
              machine.status_name,machine.osystem,machine.distro_series,machine.power_type,machine.power_state))
exit(0)
