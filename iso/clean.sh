#!/bin/bash
/usr/bin/eject
sed -i '/init.sh/d' /etc/rc.d/rc.local
sed -i '/clean.sh/d' /etc/rc.d/rc.local
ip=`ip a |grep 'eth0'|grep 'inet'|awk -F ' |/'  '{print $6}'`
curl http://172.20.102.179:8000/api/v1/vmhost/disconnect/?ip=${ip}
rm -rf /root/init
reboot
