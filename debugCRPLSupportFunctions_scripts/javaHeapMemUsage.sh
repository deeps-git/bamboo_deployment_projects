#!/bin/bash

while :
do
pidJ=$(pgrep java)
pidJava=`echo "${pidJ}" | head -1`
totalHeapMemKb=$(jstat -gc $pidJava | tail -1 | awk '{split($0,a," "); sum=a[3]+a[4]+a[6]+a[8]; print sum}')
totalHeapMemMb=$(bc -l <<< "scale=3;($totalHeapMemKb) / 1024")
#echo ${totalHeapMemMb}Mb
percentHeapUsed=$(bc -l <<< "scale=3;($totalHeapMemMb) / 1024*100")
echo "$percentHeapUsed% is being used for Heap Mem" >> /opt/cronJobs/testText.txt

awk '/^Mem/ {printf("%u%%", 100*$3/$2);}' <(free -m) >> /opt/cronJobs/testText.txt
printf " RAM Usage" >> /opt/cronJobs/testText.txt; printf ' ' >> /opt/cronJobs/testText.txt
date >> /opt/cronJobs/testText.txt
freeMem=$( awk '/^Mem/ {printf(100*$3/$2);}' <(free -m) )
let setUsage=85
if (( $(echo "$percentHeapUsed > $setUsage" | bc -l) )); then
echo "Heap Memory $percentHeapUsed usage is above $setUsage% +|+ Restarting APWS now" >> /opt/cronJobs/testText.txt
sudo /etc/init.d/accountProvisioningWebService restart
else
echo "Heap Memory $percentHeapUsed usage is below $setUsage% | No Actions Needed" >> /opt/cronJobs/testText.txt
fi
sudo curl -s http://localhost:9027/accountProvisioningWebService/management/health?forceAlive >> /opt/cronJobs/testText.txt
echo >> /opt/cronJobs/testText.txt
fileLines=$(grep -w "pattern" -c -v /opt/cronJobs/testText.txt)
echo "$fileLines lines currently in log text file" >> /opt/cronJobs/testText.txt
echo >> /opt/cronJobs/testText.txt
sleep 10m
done
