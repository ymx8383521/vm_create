#!/usr/bin/env python3
import os,sys
BASE_DIR=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(BASE_DIR)
from utils import bash


if __name__ == '__main__':
    live='ps -ef |grep "create_vm_start.py"|grep -v grep|wc -l'
    stdout,stderr=bash(live)
    if stdout.decode('utf-8') == 0:
        start='/usr/bin/python3 /export/VMWare_Auto/vm_create/bin/create_vm_start.py &>/dev/null'
        bash(start)