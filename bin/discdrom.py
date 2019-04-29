#!/usr/bin/env python3
import os,sys
BASE_DIR=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(BASE_DIR)
import settings
from utils import bash
from utils import my_logger


def disconnect(dc,vm_name):
    logger=my_logger()
    if dc == 'two':
        vcent_user,vcent_pass,vcent_ip = settings.TVCENTER_USER, settings.TVCENTER_PASSWORD, settings.TVCENTER_IP
    elif dc == 'san':
        vcent_user,vcent_pass,vcent_ip = settings.SVCENTER_USER, settings.SVCENTER_PASSWORD, settings.SVCENTER_IP
    else:
        vcent_user,vcent_pass,vcent_ip = settings.FVCENTER_USER, settings.FVCENTER_PASSWORD, settings.FVCENTER_IP
    dis='govc device.disconnect -u "%s":"%s"@"%s" -k -dc="%s" -vm "%s" cdrom-3000' \
    %(vcent_user,vcent_pass,vcent_ip,dc,vm_name)
    stdout, stderr = bash(dis)
    if stderr:
        logger.error('机房: %s VM_Name: %s cdrom断开连接失败 %s' % (dc, vm_name, stderr.decode('utf-8')))
    else:
        logger.info('机房: %s VM_Name: %s cdrom已断开连接' % (dc, vm_name))


if __name__ == '__main__':
    dc=sys.argv[1]
    vm_name=sys.argv[2]
    if dc and vm_name:
        disconnect(dc, vm_name)
