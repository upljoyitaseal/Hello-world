#! /bin/bash
ping -c10 8.8.8.8

#------------------ Check if network up,if not up logs won't be uploaded and deleted.
if [ $? != 0 ] 
then 
echo "No Network connection hence not uploaded the logs..."

#-----------If network connection is up logs would be uploaded and then deleted.
else
filename=$(echo $(date '+%a_%H'))

dirPath=/home/pi/pp/pp-tools

#Creating the zip file name as per the serial number of the device
zipname=$(cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2)

cd $dirPath

#Creating  directory logNew and pm2Log inside logNew
mkdir logNew
mkdir logNew/pm2Log

#Moving log files to directory
mv -f  log/* logNew

#Copying the syslog file to logNew folder
sudo cp /var/log/syslog logNew/systemLog

#Copying the syslog file to logNew folder
sudo cp /var/log/messages logNew/systemMessages

#Copying pm2 log files to logNew folder
sudo cp /home/pi/.pm2/logs/*.log logNew/pm2Log

cd logNew

#Zipping pm2Log folder
sudo zip -r pm2Log.zip pm2Log

sudo rm -r pm2Log

cd ..

#Zipping logNew folder
sudo zip -r $filename.zip logNew

#Uploading zipped folder to drive.
rclone copy /home/pi/pp/pp-tools/$filename.zip "WV_PP_Fusion:/LOG_Data/"$zipname"/"

#Deleting Contents of logNew
sudo rm -r $dirPath/logNew/*

#Deleting the zip files
sudo rm -r $dirPath/$filename.zip

fi
