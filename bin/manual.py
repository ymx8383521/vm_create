import os,sys
BASE_DIR=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(BASE_DIR)
from src.vm_cmd import AutoVM
from utils import get_args
from utils import my_logger
from utils import patch_installed
from utils import set_discdrom
import settings
import json


def run():
    logger=my_logger()
    conf_path = os.path.join(BASE_DIR, 'manual_vm.json')
    with open(conf_path,'r',encoding='utf-8') as f:
        res=f.read()
    res=json.loads(res)
    # print(type(res),res.get('results'))
    if res.get('results'):
        install_li=res.get('results')
        logger.debug(install_li)
        if install_li:
            for item in install_li:
                # starting=True
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
                    print('%s正在创建中' % item["vm_ip"])
                    vm_obj.create_VM()
                    # 启用cpu mem热插拔
                    vm_obj.hot_plug()
                    # 设置清理脚本断开cdrom功能
                    set_discdrom(item["room_name"],item["vm_name"])
                    # 打包镜像
                    print("打包镜像")
                    vm_obj.iso_pac()
                    # 上传镜像
                    print("上传镜像")
                    up=vm_obj.upload_iso(settings.ISO_LOCAL)
                    if up:
                        # 开机自动安装
                        vm_obj.power_on()
                        # 设置api为已安装
                        # patch_url= settings.URL + '%s/' % item["id"]
                        # patch_installed(patch_url)
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
                    print('Successful 机房:%s 虚拟机:%s 装机中...请稍后再试'%(item["room_name"],item["vm_name"]))
                    logger.info('Successful 机房:%s 虚拟机:%s 装机中...请稍后再试'%(item["room_name"],item["vm_name"]))
                except Exception as e:
                    logger.error('机房:%s 虚拟机:%s 装机失败，请查看失败原因并手动删除主机 %s'%(item["room_name"],item["vm_name"],e))
                    continue


if __name__ == '__main__':
    run()
