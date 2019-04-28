#!/bin/bash
/usr/bin/eject
sed -i '/init.sh/d' /etc/rc.d/rc.local
sed -i '/clean.sh/d' /etc/rc.d/rc.local
rm -rf /root/init
reboot
