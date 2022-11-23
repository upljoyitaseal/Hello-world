#! /bin/bash

APFILE=/var/tmp/aplock.lock

if [ -f "$APFILE" ]
then
echo "$APFILE exists"
else
ping 8.8.8.8 -c 10
if [ $? != 0 ]
then
echo "Restarting DHCPCD"
sudo systemctl restart dhcpcd
else
echo "Network is up!!"
fi
fi


