#!/bin/bash

#关闭防火墙和selinux
firewalld_selinux () {
	systemctl stop firewalld.service 
	systemctl disable firewalld.service
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux
}

# Dns
Dns () {
	cat > /etc/resolv.conf << -EOF
nameserver 114.114.114.114
options timeout:2 attempts:1
-EOF
	# chattr +i /etc/resolv.conf #防止NetworkManager刷dns
}

#安装软件
Install_pack () {
	yum clean all
	yum makecache
	yum -y install wget epel-release zlib zlib-devel bash-completion vim lsof git unzip lrzsz htop ntpdate net-tools rsync telnet
	wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
	wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
	wget -O /etc/yum.repos.d/docker-ce.repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
}


# 调整描述符
Ulimit () {
	sed -i '/^#DefaultLimitNOFILE=/aDefaultLimitNOFILE=1048576' /etc/systemd/system.conf
	sed -i '/^#DefaultLimitNPROC=/aDefaultLimitNPROC=1048576' /etc/systemd/system.conf
	sed -i '/^#DefaultLimitNOFILE=/aDefaultLimitNOFILE=1048576' /etc/systemd/user.conf
	sed -i '/^#DefaultLimitNPROC=/aDefaultLimitNPROC=1048576' /etc/systemd/user.conf
	sed -i 's/^*/#*/g' /etc/security/limits.d/20-nproc.conf
}

# 关闭不必要的服务
Shut_service () {
	SvcDisable=(NetworkManager postfix)
	for x in ${SvcDisable[@]};do
  		systemctl stop $x
  		systemctl disable $x
	done
}

# 加入key
Add_key () {
	mkdir /root/.ssh
	chmod 700 /root/.ssh/
	cat >> /root/.ssh/authorized_keys << -EOF
-EOF
	chmod 600 /home/admin/.ssh/*
	chown admin.admin /home/admin/.ssh/ -R
}

# 调整内核
Kernel () {
	cat >> /etc/sysctl.conf << -EOF
#关闭ipv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
# 避免放大攻击
net.ipv4.icmp_echo_ignore_broadcasts = 1
# 开启恶意icmp错误消息保护
net.ipv4.icmp_ignore_bogus_error_responses = 1
#关闭路由转发
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
#开启反向路径过滤
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
#处理无源路由的包
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
#关闭sysrq功能
kernel.sysrq = 0
#core文件名中添加pid作为扩展名
kernel.core_uses_pid = 1
# 开启SYN洪水攻击保护
net.ipv4.tcp_syncookies = 1
#修改消息队列长度
kernel.msgmnb = 65536
kernel.msgmax = 65536
#设置最大内存共享段大小bytes
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
#timewait的数量，默认180000
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096        87380   4194304
net.ipv4.tcp_wmem = 4096        16384   4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
#每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目
net.core.netdev_max_backlog = 262144
#限制仅仅是为了防止简单的DoS 攻击
net.ipv4.tcp_max_orphans = 3276800
#未收到客户端确认信息的连接请求的最大值
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
#内核放弃建立连接之前发送SYNACK 包的数量
net.ipv4.tcp_synack_retries = 1
#内核放弃建立连接之前发送SYN 包的数量
net.ipv4.tcp_syn_retries = 1
#启用timewait 快速回收
net.ipv4.tcp_tw_recycle = 1
#开启重用。允许将TIME-WAIT sockets 重新用于新的TCP 连接
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 2
#当keepalive 起用的时候，TCP 发送keepalive 消息的频度。缺省是2 小时
net.ipv4.tcp_keepalive_time = 1800
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 15
#允许系统打开的端口范围
net.ipv4.ip_local_port_range = 1024    65000
# 确保无人能修改路由表
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
-EOF
sysctl -p
}

#加入时间服务器
Ntp_crond () {
	echo "01 6 * * 1   /usr/sbin/ntpdate ntp1.aliyun.com" >> /var/spool/cron/root
}

# 优化sshd
Config_sshd () {
	sed -i -r 's/^[#]?UseDNS.*/UseDNS no/g' /etc/ssh/sshd_config
	sed -i -r 's/^GSSAPIAuthentication yes/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
	sed -i 's/^[ \t]*GSSAPIAuthentication yes/\tGSSAPIAuthentication no/g' /etc/ssh/ssh_config
	systemctl restart sshd
}

#配置history
History () {
        cat >> /etc/profile.d/history.sh << -EOF
STTIMEFORMAT="%F %T `whoami`"
HISTFILESIZE=10000
HISTSIZE=2000
HISTFILE=/var/log/.commandline_warrior
shopt -s histappend
PROMPT_COMMAND='history -a;history -w'
-EOF
        chmod +x /etc/profile.d/history.sh
        source /etc/profile.d/history.sh
}

# 其他优化phy
Others_phy () {
	chmod +x /etc/rc.d/rc.local
	echo "/usr/sbin/ntpdate -u ntp1.aliyun.com;clock -w" >> /etc/rc.d/rc.local
	echo "cpupower -c all frequency-set -g performance" >> /etc/rc.d/rc.local
	timedatectl set-local-rtc 1
	timedatectl set-timezone Asia/Shanghai	
}

# 其他优化vir
Others_vir () {
	chmod +x /etc/rc.d/rc.local
	echo "/usr/sbin/ntpdate -u ntp1.aliyun.com" >> /etc/rc.d/rc.local
	timedatectl set-timezone Asia/Shanghai	
}

Physical () {
	Install_pack
	Ulimit
	Shut_service
	Kernel
	Ntp_crond
	Config_sshd
	History
	Others_phy
}

Virtual () {
    Install_pack
    Ulimit
    Shut_service
    Kernel
    Ntp_crond
    Config_sshd
    History
    Others_vir
}

SN=$(dmidecode -s system-serial-number|grep -v '^#'|awk '{print $1}')
if [[ $SN =~ "VMware" ]];then
	Virtual
else
	Physical
fi	
