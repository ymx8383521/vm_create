import os
BASE_DIR=os.path.dirname(os.path.abspath(__file__))

# 一VCenter账号密码
FVCENTER_USER = ''
FVCENTER_PASSWORD = ''
FVCENTER_IP = ''

# 二VCenter账号密码
TVCENTER_USER = '2'
TVCENTER_PASSWORD = ''
TVCENTER_IP = ''

# 三VCenter账号密码
SVCENTER_USER = ''
SVCENTER_PASSWORD = ''
SVCENTER_IP = ''

ISO_LOCAL = os.path.join(BASE_DIR,'./iso/CentOS-7-x86_64_my-DVD-1810.iso')
ISO_NONE_LOCAL = os.path.join(BASE_DIR,'./iso/CentOS-7-x86_64_my-DVD-1810_none.iso')
ISO_REMOTE = 'iso/CentOS-7-x86_64_my-DVD-1810.iso'
ISO_ROOT = '/opt/dvd_iso'

# 访问的URL
URL='http://127.0.0.1:8000/api/v1/vmhost/'

# 主机名前缀
HOSTNAMEPRE='jitua'

#日志配置
LOGGING_CONFIG={
    "version":1,
    "disable_existing_loggers":False,
    "formatters":{
        "simple":{
            "format":"%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        }
    },
    "filters": {},
    "handlers":{
        "console":{
            "class":"logging.StreamHandler",
            "level":"DEBUG",
            "formatter":"simple"
        },
        "file_handler":{
            "class":"logging.handlers.RotatingFileHandler",
            "level":"INFO",
            "formatter":"simple",
            "filename":"vminfo.log",
            "maxBytes":10485760,
            "backupCount":10,
            "encoding":"utf-8"
        }
    },
    "loggers":{
        "":{
            "level":"INFO",
            "handlers":["console","file_handler"],
            "propagate":True
        }
    }
}
