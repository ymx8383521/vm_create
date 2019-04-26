import settings
from utils import bash
from utils import to_dic
from utils import my_logger
from utils import set_hostname,set_netsh


class AutoVM(object):
    def __init__(self,vc_user,vc_pass,vc_ip,dc, host_ip, ds, vm_ip, vm_gateway, vm_cpu, vm_mem, vm_disk, vm_name, operator,id):
        self.id=id
        self.dc=dc
        self.host_ip=host_ip
        self.ds=ds
        self.vm_ip=vm_ip
        self.vm_gateway=vm_gateway
        if not str(vm_cpu).isdigit():raise Exception('vm_cpu must be number')
        self.vm_cpu=int(vm_cpu)
        if not str(vm_mem).isdigit():raise Exception('vm_mem must be number')
        self.vm_mem=int(vm_mem)*1024
        if not str(vm_disk).isdigit(): raise Exception('vm_disk must be number')
        self.vm_disk=str(vm_disk)+'GB'
        self.vm_name=vm_name
        self.operator=operator
        self.logger=my_logger()
        self.vc_user=vc_user
        self.vc_pass=vc_pass
        self.vc_ip=vc_ip

    def create_VM(self):
        """
        创建虚拟机还未安装系统,需要先上传upload_iso
        :return:
        """
        # 判断数据中心是否有相同的虚拟机名称
        current_li=self.get_datastore()
        if self.vm_name in current_li:
            self.logger.error('VM_Name: %s 虚拟机已经存在了'% self.vm_name)
            raise Exception('VM_Name: %s 虚拟机已经存在了'% self.vm_name)
        # 判断iso文件是否存在，不存在就上传
        iso_file=(settings.ISO_REMOTE).rsplit('/', 1)[-1]
        remote_file=self.get_datastore("iso")
        if iso_file not in remote_file:
            self.upload_iso(settings.ISO_NONE_LOCAL)
        create='govc vm.create -u "%s":"%s"@"%s" -k -dc="%s" -ds="%s" -host.ip="%s" \
                    -m %d -c %d  -disk "%s" -g centos7_64Guest -on=false \
                    -firmware=bios -net="VM Network" -net.adapter vmxnet3 -disk.controller pvscsi \
                    -iso "%s" "%s"' % (
        self.vc_user, self.vc_pass, self.vc_ip, self.dc, self.ds, self.host_ip,
        self.vm_mem, self.vm_cpu, self.vm_disk, settings.ISO_REMOTE, self.vm_name)
        stdout,stderr=bash(create)
        if stderr:
            self.logger.error('ID: %d 机房:%s VM_Name: %s 创建失败 %s'%(self.id,self.dc,self.vm_name,stderr.decode('utf-8')))
            raise Exception('ID: %d 机房:%s VM_Name: %s 创建失败 %s'%(self.id,self.dc,self.vm_name,stderr.decode('utf-8')))
        else:
            self.logger.info('ID: %d 机房:%s VM_Name: %s 创建成功' % (self.id, self.dc,self.vm_name))
        return True

    def hot_plug(self):
        """
        cpu和内存启用热插拔
        :return:
        """
        hotadd='govc vm.change -u "%s":"%s"@"%s" -k -dc="%s" -vm %s -e vcpu.hotadd=true -e mem.hotadd=true' \
               %(self.vc_user, self.vc_pass, self.vc_ip, self.dc, self.vm_name)
        stdout, stderr = bash(hotadd)
        if stderr:
            self.logger.error('机房: %s VM_Name: %s CPU和MEM启用热插拔失败 %s' % (self.dc, self.vm_name, stderr.decode('utf-8')))
        else:
            self.logger.info('机房: %s VM_Name: %s CPU和MEM已启用热插拔' % (self.dc, self.vm_name))

    def get_VM_info(self):
        """
        获取虚拟机信息
        :return:
        """
        get_vm_info = 'govc vm.info -u  "%s":"%s"@"%s" -k -dc="%s" -vm.path="[%s] %s/%s.vmx" -r'\
                      %(self.vc_user, self.vc_pass, self.vc_ip, self.dc, self.ds, self.vm_name, self.vm_name)
        stdout,stderr=bash(get_vm_info)
        if stdout:
            li=stdout.decode('utf-8').split('\n')
            stdout=to_dic(li)
        # print(stdout.decode('utf-8'))
        return stdout,stderr

    def check_VM_info(self,vm_stdout):
        """
        验证虚拟机硬件是否创建成功
        :param vm_stdout:
        :return:
        """
        get_os=vm_stdout.get('Guest name')
        get_mem=vm_stdout.get('Memory')
        get_cpu=vm_stdout.get('CPU')
        if get_cpu:
            get_cpu=get_cpu.split(' ')[0]
        get_storage=vm_stdout.get('Storage')
        if get_os == 'CentOS 7 (64-bit)' and get_mem == str(self.vm_mem)+'MB' and get_cpu == str(self.vm_cpu) and get_storage == self.ds:
            self.logger.info('ID: %d VM_Name: %s 验证成功' % (self.id, self.vm_name))
            return True
        else:
            self.logger.error('ID: %d VM_Name: %s 验证失败，请重新创建' % (self.id, self.vm_name))
            raise Exception('ID: %d VM_Name: %s 验证失败，请重新创建' % (self.id, self.vm_name))

    def get_datastore(self,file=""):
        '''
        获取存储中心的文件,可以检查新建虚拟机名是否存在
         ['jituan-xiaofeifenqi-test-211', 'CentOS-6.9-x86_64-bin-DVD1.iso']
        :return:
        '''
        datastore_ls='govc datastore.ls -u  "%s":"%s"@"%s" -k -dc="%s" -ds="%s" %s'\
                      %(self.vc_user, self.vc_pass, self.vc_ip, self.dc, self.ds, file)
        stdout,stderr=bash(datastore_ls)
        datastore_li=stdout.decode('utf-8').strip().split('\n')
        return datastore_li

    def get_mac(self):
        """
        获取网卡mac信息
        :return:
        """
        mac_cmd='govc device.info -u "%s":"%s"@"%s" -k -dc="%s" -vm "%s" -json ethernet-0 |jq -r .Devices[].MacAddress'\
                      %(self.vc_user, self.vc_pass, self.vc_ip, self.dc, self.vm_name)
        stdout,stderr=bash(mac_cmd)
        if stdout:
            stdout=stdout.decode('utf-8')
        return stdout,stderr

    def iso_pac(self):
        """
        镜像iso打包
        isolinux.cfg 指向ks.cfg
        ks.cfg自动安装
        """
        # 设置ks.cfg中的主机名 生成net.sh脚本
        set_hostname(self.vm_ip)
        set_netsh(self.vm_ip,self.vm_gateway)
        pac='genisoimage -quiet -cache-inodes -joliet-long -input-charset utf-8 -R -J -T -V CentOS7 -o %s -c isolinux/boot.cat -b \
                    isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -b \
                    images/efiboot.img -no-emul-boot %s'%(settings.ISO_LOCAL, settings.ISO_ROOT)
        stdout,stderr=bash(pac)
        if stderr:
            self.logger.error('VM_Name: %s 镜像iso打包失败 %s' % (self.vm_name,stderr))
            raise Exception('VM_Name: %s 镜像iso打包失败 %s' % (self.vm_name,stderr))
        else:
            self.logger.info('VM_Name: %s 镜像iso打包完成' % (self.vm_name))
        return True

    def upload_iso(self,upload_file):
        """
        上传镜像到iso/CentOS-7-x86_64_hexin-DVD-1804.iso
        upload_iso(settings.ISO_NONE_LOCAL)
        :return:
        """
        if 'iso' not in self.get_datastore():
            mk_folder='govc datastore.mkdir -u  "%s":"%s"@"%s" -k -dc="%s" -ds="%s" iso'\
                      %(self.vc_user, self.vc_pass, self.vc_ip, self.dc, self.ds)
            stdout,stderr=bash(mk_folder)
            if stderr:
                self.logger.info('机房: %s 数据中心: %s 创建iso文件夹成功' % (self.dc,self.ds))
                raise Exception('机房: %s 数据中心: %s 创建iso文件夹成功' % (self.dc,self.ds))
        #开始上传iso到文件夹
        self.logger.info('机房: %s 数据中心: %s 开始上传iso文件%s' % (self.dc, self.ds, upload_file))
        upload='govc datastore.upload -u  "%s":"%s"@"%s" -k -dc="%s" -ds="%s" %s %s'\
                      %(
               self.vc_user, self.vc_pass, self.vc_ip, self.dc, self.ds, upload_file,
               settings.ISO_REMOTE)
        upstdout,upstderr=bash(upload)
        if upstderr:
            self.logger.error('机房: %s 数据中心: %s 上传iso文件%s失败' % (self.dc, self.ds,upload_file))
            raise Exception('机房: %s 数据中心: %s 上传iso文件%s失败' % (self.dc, self.ds,upload_file))
        else:
            self.logger.info('机房: %s 数据中心: %s 上传iso文件%s成功' % (self.dc, self.ds,upload_file))
        return True

    def power_on(self):
        """
        开机
        :return:
        """
        poweron='govc vm.power -u  "%s":"%s"@"%s" -k -dc="%s" -vm.path="[%s] %s/%s.vmx" -on=True' \
                % (self.vc_user, self.vc_pass, self.vc_ip, self.dc, self.ds, self.vm_name, self.vm_name)
        stdout,stderr=bash(poweron)
        if stderr:
            self.logger.error('机房: %s VM_Name: %s 启动失败 %s'%(self.dc,self.vm_name,stderr.decode('utf-8')))
            raise Exception('机房: %s VM_Name: %s 启动失败 %s'%(self.dc,self.vm_name,stderr.decode('utf-8')))
        else:
            self.logger.info('机房: %s VM_Name: %s 启动安装中' % (self.dc,self.vm_name))
        return True

    def connect_cdrom(self,connect=True):
        """
        连接cdrom
        需要在服务器内eject先
        govc device.ls -u "" -k -dc "" -vm ""
        :param connect:True 连接 False 断开
        :return:
        """
        if connect:
            connect = 'govc device.connect -u "%s":"%s"@"%s" -k -dc="%s" -vm "%s"  cdrom-3000' \
                         % (
                      self.vc_user, self.vc_pass, self.vc_ip, self.dc, self.vm_name)
            stdout, stderr = bash(connect)
            if stderr:
                self.logger.error('机房: %s VM_Name: %s cdrom连接失败 %s' % (self.dc, self.vm_name, stderr.decode('utf-8')))
            else:
                self.logger.info('机房: %s VM_Name: %s cdrom已连接' % (self.dc, self.vm_name))
        else:
            disconnect='govc device.disconnect -u "%s":"%s"@"%s" -k -dc="%s" -vm "%s" cdrom-3000' \
            % (self.vc_user, self.vc_pass, self.vc_ip, self.dc, self.vm_name)
            stdout, stderr = bash(disconnect)
            if stderr:
                self.logger.error('机房: %s VM_Name: %s cdrom断开连接失败 %s' % (self.dc, self.vm_name, stderr.decode('utf-8')))
            else:
                self.logger.info('机房: %s VM_Name: %s cdrom已断开连接' % (self.dc, self.vm_name))
        return True


# if __name__ == '__main__':
#
#     vm_obj=AutoVM('机房名','172.20.10.2','datastore1 (4)','172.20.10.25','172.20.10.1','4','4','100','test-253','申请人',9)
    # vm_obj.create_VM()
    # stdout,stderr=vm_obj.get_vm_info()
    # stdout,stderr=vm_obj.get_mac()
    # vm_obj.iso_pac()
    # vm_obj.check_vm_info(stdout)
    # print(vm_obj.get_datastore("iso"))
    # print(vm_obj.upload_iso())
    # up=vm_obj.upload_iso('CentOS-7-x86_64_hexin-DVD-1804.iso')
    # if up:
    #     vm_obj.power_on()
    # vm_obj.connect_cdrom(connect=True)
    # print(stdout)
