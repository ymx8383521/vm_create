[TOC]

------



# 1、vm_create

## 1.1.定义开机密码

### 1.1.1安装perl

```shell
wget http://www.cpan.org/src/5.0/perl-5.26.1.tar.gz
tar zxvf perl-5.26.1.tar.gz
cd perl-5.26.1
./Configure -de
make
make test
make install
```

### 1.1.2执行命令

```shell
perl -e "print crypt('passwd','\$1\$VSmile07');"
#生成加密字符串
$1$VSmile07$LbhX2jBSGwPqFQGCGpmUc/
```

### 1.1.3更改程序

`vim vm_create/utils.py`

```python 
# 打包相关
def set_password(ip):
    ks_path=os.path.join(settings.ISO_ROOT, 'isolinux', 'ks.cfg')
    test=re.match(r'^10.1.1.*',ip)
    if test:
        #根据需求更改变量 passwd，在所有$前 添加转义字符\
        passwd='\$1\$VSmile07\$LbhX2jBSGwPqFQGCGpmUc/'
    else:
        passwd='\$1\$VSmile07sdfadf.gs'
    set_passwd='sed -i "s/rootpw --iscrypted .*/rootpw --iscrypted %s/" %s'%(passwd,ks_path)
    stdout,stderr=bash(set_passwd)
    if stderr:
        raise Exception('设置ks.cfg文件中设置密码失败 %s'%stderr)
    return True
```

## 1.2.挂载iso镜像文件并更改配置

### 1.2.1挂载iso文件并拷贝

```bash
[root@vcenter-create ~]$ mount -o loop /root/CentOS-7-x86_64-Minimal-1804.iso /mnt/dvd_iso/
[root@vcenter-create ~]$ mkdir /opt/dvd_iso
[root@vcenter-create ~]$ cp /mnt/dvd_iso/* /opt/dvd_iso/ -rp
[root@vcenter-create ~]$ genisoimage -v -cache-inodes -joliet-long -R -J -T -V CentOS7 -o "/root/CentOS-7-x86_64-Minimal-1804.iso" -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -b images/efiboot.img -no-emul-boot /opt/dvd_iso
```

### 1.2.2更改iso配置

`vim vm_create/settings.py`

```python
#生成ISO后的路径
ISO_LOCAL = os.path.join(BASE_DIR,'./iso/')
#touch空的iso即可
ISO_NONE_LOCAL = os.path.join(BASE_DIR,'./iso/CentOS-7-x86_64-Minimal-1804_none.iso')
#vcenter上的存储路径
ISO_REMOTE = 'iso/CentOS-7-x86_64-Minimal-1804.iso'
#用这个目录里的文件去生成iso
ISO_ROOT = '/opt/dvd_iso'
```

## 1.3.更改vcenter的账号密码

<!--vcenter密码最好只有＠符号，不要有其他特殊字符，如下所示-->

`vim cm_create/settings.py`

```python 
# 一VCenter账号密码
FVCENTER_USER = 'administrator@localhost'
FVCENTER_PASSWORD = 'Passwd@123'
FVCENTER_IP = '10.0.0.1'
```

## 1.4根据需求更改vm_create/iso/init.sh文件

## 1.5根据需求更改vm_create/iso/ks.cfg文件

## 1.6创建/opt/dvd_iso/init并拷贝文件

```shell
[root@vcenter-create ~]$ mkdir /opt/dvd_iso/init
[root@vcenter-create ~]$ cd /opt/dvd_iso/init
[root@vcenter-create init]$ scp /opt/app/vm_create/iso/init.sh /opt/app/vm_create/iso/clean.sh /opt/app/vm_create/iso/jarctl.sh ./

```

## 1.7修改clean.sh中的IP

```shell
#!/bin/bash
/usr/bin/eject
sed -i '/init.sh/d' /etc/rc.d/rc.local
sed -i '/clean.sh/d' /etc/rc.d/rc.local
ip=`ip a |grep 'eth0'|grep 'inet'|awk -F ' |/'  '{print $6}'`
#修改下方ip为 程序所在机器的ip
curl http://172.20.102.179:8000/api/v1/vmhost/disconnect/?ip=${ip}
#sshpass -p "1234567" ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no root@172.23.10.59 "python3 /export/VMWare_Auto/vm_create/bin/discdrom.py '机房' vm_name"
rm -rf /root/init
reboot
```

## 1.8拷贝ks.cfg和isolinux.cfg到/opt/dvd_iso/isolinux

## 1.9下载govc命令

```shell
[root@vcenter-create ~]$ wget https://github.com/vmware/govmomi/releases/download/v0.20.0/govc_linux_amd64.gz
[root@vcenter-create ~]$ gunzip govc_linux_amd64.gz
[root@vcenter-create ~]$ mv govc_linux_amd64 /usr/bin/govc
[root@vcenter-create ~]$ chmod +x /usr/bin/govc
```

## 1.10测试govc

```shell
[root@vcenter-create ~]$ govc about -u "vc_user":"vc_passwd"@"vc_ip" -k
Name:         VMware vCenter Server
Vendor:       VMware, Inc.
Version:      6.7.0
Build:        13639324
OS type:      linux-x64
API type:     VirtualCenter
API version:  6.7.2
Product ID:   vpx
UUID:         bb0301ac-t46c-483e-8850-2c644y7a3d87
```

## 1.11修改机房名称

`vim vm_create/src/main.py`

```python
def run():
    logger=my_logger()
    get_url= settings.URL + '?vm_audit=1&vm_installed=0'
    res=get_args(get_url)
    install_li=res.get('results')
    logger.debug(install_li)
    if install_li:
        for item in install_li:
            starting=True
            try:
                #修改下面room_name为机房名称
                if item["room_name"] == 'room_name':
                    vm_obj=AutoVM(settings.FVCENTER_USER,settings.FVCENTER_PASSWORD,settings.FVCENTER_IP,item["room_name"],item["host_ip"],item["datastore"],item["vm_ip"],item["vm_gateway"],item["vm_cpu"],item["vm_memory"],item["vm_disk"],item["vm_name"],item["vm_proposer"],item["id"])
```

 `vim vm_create/bin/discdrom.py`              

```python
def disconnect(dc,vm_name):
    logger=my_logger()
    #修改room_name 
    if dc == 'room_name':
        vcent_user,vcent_pass,vcent_ip = settings.TVCENTER_USER, settings.TVCENTER_PASSWORD, settings.TVCENTER_IP
```



