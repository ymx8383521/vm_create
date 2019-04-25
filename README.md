# 获取govc命令
```
wget https://github.com/vmware/govmomi/releases/download/v0.20.0/govc_linux_amd64.gz
gunzip govc_linux_amd64.gz
mv govc_linux_amd64 /usr/bin/govc
chmod +x /usr/bin/govc
```
# 启动VCenter自动装机程序
`python3 bin/create_vm_start.py`
# 参数格式：
`GET http://127.0.0.1:8000/api/v1/vmhost/?vm_audit=1&vm_installed=0`
```json
{
    "count": 1,
    "next": null,
    "previous": null,
    "results": [
        {
            "id": 26,
            "vm_name": "test-253",
            "vm_cpu": 4,
            "vm_memory": 4,
            "vm_os": "centos7",
            "vm_disk": 100,
            "vm_ip": "172.20.10.253",
            "vm_gateway": "172.20.10.1",
            "vm_audit": 1,
            "vm_proposer": "woshiceshi1",
            "host_ip": "172.20.10.21",
            "room_name": "机房",
            "datastore": "datastore1 (0)",
            "vm_installed": 0
        }
    ]
}
```
# 打包 iso 命令
yum -y install genisoimage sshpass
```
genisoimage -v -cache-inodes -joliet-long -R -J -T -V CentOS7 -o "/mnt/CentOS-7-x86_64_my-DVD-1804.iso" -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -b images/efiboot.img -no-emul-boot /opt/dvd_iso
```
####### 先下载mini版centos镜像文件 挂载拷贝到/opt/dvd_iso  
####### 编辑 isolinux/ks.cfg 自动安装配置文件  
####### 修改isolinux/isolinux.cfg为ks.cfg文件引导  
####### init/init.sh为安装完成后初始脚本设置  
####### init/clean.sh清理init文件夹并重启  