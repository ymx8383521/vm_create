from src.vm_cmd import AutoVM
from utils import get_args
from utils import my_logger
from utils import patch_installed
from utils import judgment_on
import settings
import time


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
                if item["room_name"] == 'yi':
                    vm_obj=AutoVM(settings.FVCENTER_USER,settings.FVCENTER_PASSWORD,settings.FVCENTER_IP,item["room_name"],item["host_ip"],item["datastore"],item["vm_ip"],item["vm_gateway"],item["vm_cpu"],item["vm_memory"],item["vm_disk"],item["vm_name"],item["vm_proposer"],item["id"])
                elif item["room_name"] == 'two':
                    vm_obj=AutoVM(settings.TVCENTER_USER,settings.TVCENTER_PASSWORD,settings.TVCENTER_IP,item["room_name"],item["host_ip"],item["datastore"],item["vm_ip"],item["vm_gateway"],item["vm_cpu"],item["vm_memory"],item["vm_disk"],item["vm_name"],item["vm_proposer"],item["id"])
                elif item["room_name"] == 'san':
                    vm_obj = AutoVM(settings.SVCENTER_USER, settings.SVCENTER_PASSWORD, settings.SVCENTER_IP,
                                    item["room_name"], item["host_ip"], item["datastore"], item["vm_ip"],
                                    item["vm_gateway"], item["vm_cpu"], item["vm_memory"], item["vm_disk"],
                                    item["vm_name"], item["vm_proposer"], item["id"])
                else:
                    raise Exception('机房名称错误')
                # 创建虚拟机
                vm_obj.create_VM()
                # 启用cpu mem热插拔
                vm_obj.hot_plug()
                # 打包镜像
                vm_obj.iso_pac()
                # 上传镜像
                up=vm_obj.upload_iso(settings.ISO_LOCAL)
                if up:
                    # 开机自动安装
                    vm_obj.power_on()
                    # 设置api为已安装
                    patch_url= settings.URL + '%s/' % item["id"]
                    patch_installed(patch_url)
                # # 判断启动成功并断开cdrom
                # count=0
                # while starting and count<34:
                #     on=judgment_on(item["vm_ip"])
                #     if on:
                #         vm_obj.connect_cdrom(connect=False)
                #         starting=False
                #     else:
                #         time.sleep(10)
                #         count += 1
                logger.info('Successful 机房:%s 虚拟机:%s 装机中...请稍后再试'%(item["room_name"],item["vm_name"]))
            except Exception as e:
                logger.error('机房:%s 虚拟机:%s 装机失败，请查看失败原因并手动删除主机 %s'%(item["room_name"],item["vm_name"],e))
                continue


if __name__ == '__main__':
    run()
