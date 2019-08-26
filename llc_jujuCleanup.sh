#!/bin/bash
echo "\n****  $(date '+%Y-%m-%d %H:%M:%S') - Starting llc_jujuCleanup.... ****"

# Remove any leftover failed backup
rm -fr /tmp/jujuBackup*

# Purge old kernels
purge-old-kernels --keep 2 -qy

# Remove unneeded packages
apt-get autoremove -y

echo "**** $(date '+%Y-%m-%d %H:%M:%S') - Exiting llc_jujuCleanup.... ****"
exit 0

