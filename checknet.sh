#! /bin/bash

# Output the standard errors and messages of rc.local executions to rc.local.log file.
exec 2> /home/pi/pp/pp-tools/log/checknet.log
exec 1>&2

# Defined common WLAN and AP Interface names here as in the recent and future versions of Debian based OS 
# may change the Networking Interface name.
wlanInterfaceName="wlan0"
apInterfaceName="uap0"
hostName="ppplayer"

OS_VERSION=`cat /etc/os-release 2>/dev/null | grep -i "VERSION_ID" | awk -F '=' '{gsub("\"", "", $2); print $2}'`
echo ""
echo "$(date +"%Y-%m-%d %T") - [INFO]: Processing network setup for OS Version: $OS_VERSION"

if [ ! -z "$( hostname )" ]; then 
    hostName="$( hostname )"
fi
echo ""
echo "$(date +"%Y-%m-%d %T") - [INFO]: Hostname is: $hostName"

#Turning off wifi power management
sudo iwconfig wlan0 power off

OS_SERIAL=`cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2`
echo "$(date +"%Y-%m-%d %T") - [INFO]: OS Serial is: $OS_SERIAL"

sudo rm -f /var/tmp/aplock.lock

# Function to switch on AP and wvConnect application
doStartAP() {

ifconfig uap0

    # Check AP name, name should be Pictplay-<SerialNo>
    CPUID=$(cat /proc/cpuinfo  |grep "Serial" | cut -f 2 -d : | tr -d " ")
    ACCESS_POINT_NAME=$(echo "${CPUID: -4}")
    sed -i 's/^ssid=.*/ssid=Wallview-'$ACCESS_POINT_NAME'/' /etc/hostapd/hostapd.conf
    sed -i 's/^#DAEMON_CONF=.*$/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/' /etc/default/hostapd

    # Starting AP
    systemctl unmask hostapd

    # Make sure no uap0 interface exists (this generates an error; we could probably use an if statement to check if it exists first)
    echo "$(date +"%Y-%m-%d %T") - [INFO]: Removing uap0 interface ..."
    iw dev uap0 del

    # Add uap0 interface (this is dependent on the wireless interface being called wlan0, which it may not be in Stretch)
    echo "$(date +"%Y-%m-%d %T") - [INFO]: Adding uap0 interface ..."
    iw dev wlan0 interface add uap0 type __ap


    ifconfig uap0 up

ifconfig uap0


    # Start hostapd. 10-second sleep avoids some race condition, apparently. It may not need to be that long. (?) 
    echo "$(date +"%Y-%m-%d %T") - [INFO]: Starting hostapd service ..."
    systemctl start hostapd.service
    sleep 10

ifconfig uap0

    #Start dhcpcd. Again, a 5-second sleep
    echo "$(date +"%Y-%m-%d %T") - [INFO]: Starting dhcpcd service ..."
    systemctl start dhcpcd.service
    sleep 20


ifconfig uap0

    echo "$(date +"%Y-%m-%d %T") - [INFO]: Starting dnsmasq service ..."
    systemctl restart dnsmasq.service

#    touch /home/pi/pp/pp-tools/inAPmode

    # AP configured
    echo "$(date +"%Y-%m-%d %T") - [INFO]: AP Configured ..."
    # Turning WiFi back OFF:
    echo "$(date +"%Y-%m-%d %T") - [INFO]: Turning WiFi back OFF ..."
    sudo rfkill block wifi
    sudo ifconfig wlan0 down
    sleep 2

ifconfig uap0

    # Turning WiFi back ON:
    echo "$(date +"%Y-%m-%d %T") - [INFO]: Turning WiFi back ON ..."
    sudo rfkill unblock wifi
    sudo ifconfig wlan0 up
}

# # Function to switch off AP and wvConnect application -- NOT IN USE --
# doStopAP() {

#     # Make sure no uap0 interface exists (this generates an error; we could probably use an if statement to check if it exists first)
#     echo "$(date +"%Y-%m-%d %T") - [INFO]: Removing uap0 interface ..."
#     iw dev uap0 del

#     systemctl stop hostapd
#     systemctl stop dnsmasq
#     systemctl restart dhcpcd
#     # Turning WiFi back OFF:
#     echo "$(date +"%Y-%m-%d %T") - [INFO]: Turning WiFi back OFF ..."
#     sudo rfkill block wifi
#     sudo ifconfig wlan0 down
#     sleep 2

#     # Turning WiFi back ON:
#     echo "$(date +"%Y-%m-%d %T") - [INFO]: Turning WiFi back ON ..."
#     sudo rfkill unblock wifi
#     sudo ifconfig wlan0 up
# }

# Check if Internet is available then, AP need is not required as the device is already online
# if not available then configure AP and switch it on
n=0
until [ "$n" -ge 12 ]
do
    ip=$(ifconfig wlan0 | grep inet | awk '{ print $2 }')
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # if [ $(curl -Is http://www.google.com 2>/dev/null | head -n 1 | grep -c '200 OK') -gt 0 ]; then
        echo "$(date +"%Y-%m-%d %T") - [INFO]: Internet is available on this device, no AP activated ..."
        # doStopAP;
        break;
    else
        if [ "$n" -lt 11 ]; then
            echo "$(date +"%Y-%m-%d %T") - [INFO]: NO Internet is available to the device, Retrying ... sleeping for 5 secs [$n]"
            n=$((n+1));
            sleep 5;
        else
            n=$((n+1));
            echo "$(date +"%Y-%m-%d %T") - [AP]: Starting AP .."
        sudo touch /var/tmp/aplock.lock 
        doStartAP;
        fi
    fi
done