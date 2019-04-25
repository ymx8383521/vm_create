from src.vm_cmd import AutoVM
from utils import get_args
from utils import my_logger
from utils import patch_installed
from utils import judgment_on
import settings
import time

def run():
    logger=my_logger()
    get_url=settings.URL+'?vm_audit=1&vm_installed=0'
    res=get_args(get_url)
    install_li=res.get('results')
    logger.debug(install_li)
    if install_li:
        for item in install_li:
            starting=True
            try:
                vm_obj=AutoVM(item["room_name"],item["host_ip"],item["datastore"],item["vm_ip"],item["vm_gateway"],item["vm_cpu"],item["vm_memory"],item["vm_disk"],item["vm_name"],item["vm_proposer"],item["id"])
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
                    patch_url=settings.URL+'%s/'%item["id"]
                    patch_installed(patch_url)
                # 判断启动成功并断开cdrom
                while starting:
                    on=judgment_on(item["vm_ip"])
                    if on:
                        vm_obj.connect_cdrom(connect=False)
                        starting=False
                    else:
                        time.sleep(10)
                logger.info('Successful 机房:%s 虚拟机:%s 装机成功'%(item["room_name"],item["vm_name"]))
            except Exception as e:
                logger.error('机房:%s 虚拟机:%s 装机失败，请查看失败原因并手动删除主机 %s'%(item["room_name"],item["vm_name"],e))
                continue


if __name__ == '__main__':
    run()
