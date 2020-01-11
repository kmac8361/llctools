#!/bin/bash
echo "\n****  $(date '+%Y-%m-%d %H:%M:%S') - Starting llc_installTools....  ****"

cp llc_hostlookup.py ../python-libmaas
cp llc_iplookup.py ../python-libmaas
cp llc_modelmap.py ../python-libmaas
cp llc_libmaas_ex1.py ../python-libmaas
cp llc_powerControl.py ../python-libmaas
cp llc_libjuju_ex1.py ../python-libjuju/examples 

echo "**** $(date '+%Y-%m-%d %H:%M:%S') - Completed llc_installTools.  ****"

exit 0
