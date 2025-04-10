#!/bin/bash

if [ "$(id -un)" != "root" ]; then
    echo " "
    echo " We need root access for certain task..."
    echo " Please run as 'root'."
    echo " "
    exit
fi

if !( systemctl is-active --quiet pihole-FTL || sudo docker ps -a | grep -o "pihole" > /dev/null 2>&1 ); then
  echo " "
  echo " Pihole is currently not installed on this system."
  echo " Install Pihole (https://pi-hole.net/) before running this script."
  echo " "
  exit
fi

echo " "
echo "---------------------------------------------------------------"
echo " $(date)"
echo " Pihole DNS redirect for Lancache "
echo "   Creating setup files... "

loc=$(pwd)
cd /home/$(logname)
git clone https://github.com//uklans/cache-domains > /dev/null 2>&1

#Get host ip address
HOST=192.168.1.102
Hostip="\"$HOST\""

#Setting up config.json file
{
echo '{'
echo '  "combined_output": true,'
echo '  "ips": {'
echo '          "generic":      '$Hostip
echo '  },'
echo '  "cache_domains": {'
echo '          "default":      "generic"'
echo '  }'
echo '}'
} > config.json

echo "   Generating cache-domains files... "

          #### Automating cache-domains files

cp /$loc/lancache-dns-updates.sh /root/lancache-dns-updates.sh
cd /root
chmod +x lancache-dns-updates.sh
./lancache-dns-updates.sh

echo "   Creating crontab job... "

          # Adding the script to a cron job if it doesn't already exist
CRON_JOB="30 3 * * * /bin/bash /root/lancache-dns-updates.sh"
(crontab -u $(whoami) -l | grep -qF "$CRON_JOB") || (crontab -u $(whoami) -l; echo "$CRON_JOB") | crontab -u $(whoami) -

sudo service cron reload > /dev/null 2>&1

echo " Install Complete "
echo " Enjoy! "
echo "---------------------------------------------------------------"
echo " "
