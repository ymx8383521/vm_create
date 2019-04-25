#VCenter账号密码
VCENTER_USER = ''
VCENTER_PASSWORD = ''
VCENTER_IP = ''

ISO_LOCAL = './iso/CentOS-7-x86_64_my-DVD-1810.iso'
ISO_NONE_LOCAL = './iso/CentOS-7-x86_64_my-DVD-1810_none.iso'
ISO_REMOTE = 'iso/CentOS-7-x86_64_my-DVD-1810.iso'
ISO_ROOT = '/opt/dvd_iso'

# 访问的URL
URL='http://127.0.0.1:8000/api/v1/vmhost/'

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
