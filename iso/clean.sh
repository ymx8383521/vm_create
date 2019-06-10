#!/bin/bash
/usr/bin/eject
sed -i '/init.sh/d' /etc/rc.d/rc.local
sed -i '/clean.sh/d' /etc/rc.d/rc.local
ip=`ip a |grep 'eth0'|grep 'inet'|awk -F ' |/'  '{print $6}'`
curl http://172.20.102.179:8000/api/v1/vmhost/disconnect/?ip=${ip}
sshpass -p "1234567" ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no root@172.23.10.59 "python3 /export/VMWare_Auto/vm_create/bin/discdrom.py '机房' vm_name"
rm -rf /root/init
reboot
