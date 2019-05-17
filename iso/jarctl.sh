#!/bin/bash
#
# @Author: hubiao
# @License: (C) Copyright 2019, HXGP.
# @Contact: hubiao@hexindai.com
# @Software: jarctl
# @File: /export/script/jarctl.sh
# @Time: 2019/04/20 15:13
# @Version: 2.0
# @Description: 
# 	This is a Jar program management script in every machine which had been installed operating system according to standard;
#	and suits the projects that published with Jenkins in standard mode, Please do not modify and delete it.
# 	To get more information about that, please contact us.
#
USAGE="Usage:jarctl <command> <other_config>
      command: <-h|--help|init|start|stop|restart|list|/export/servers/jdk1.8.0_192/bin/jstat|json>
      other_config: <jar-server> <jvm> <port> <option> <pid> 
      [<interval-time> ms] <count>
Example:
        jarctl <-h|--help>
        jarctl <list> <--all>
        jarctl <init> <jar-server> <jvm> <port> <MetaspaceSize> <xmn> <other-options>
        jarctl <start> <jar-server>
        jarctl <stop> <jar-server>
        jarctl <restart> <jar-server>
        jarctl <json> <jar-server>
        jarctl </export/servers/jdk1.8.0_192/bin/jstat> <option> <pid> [<interval-time> ms] <count>"

#服务存放的路径
DeployDir=/export/servers/jar_project
#gc log
GcLogDir=/export/log
#config file
ConfigFile=config.ini

function InitServer(){
	INIT_USAGE="jarctl <init> <jar-server> <jvm> <port> <MetaspaceSize> <xmn> <other-options>"
	if [ $# -lt 6 ]; then
                echo $INIT_USAGE
                exit 1
	fi
	echo "Init $1 server"
	JarServer=$1
	JarDir=`echo "${JarServer%.*}"`
	if [ ! -d $DeployDir/$JarDir ];then 
		mkdir $DeployDir/$JarDir -p
	fi
	if [ ! -d $GcLogDir/$JarDir ];then 
		mkdir $GcLogDir/$JarDir -p
	fi
	echo "JarDir=$JarDir" > $DeployDir/$JarDir/$ConfigFile
	echo "JarServer="$1"" >> $DeployDir/$JarDir/$ConfigFile
	echo "Jvm="$2"" >> $DeployDir/$JarDir/$ConfigFile
	echo "GcLogDir=$GcLogDir" >> $DeployDir/$JarDir/$ConfigFile
	echo "Port="$3"" >> $DeployDir/$JarDir/$ConfigFile
	echo "MetaspaceSize="$4"" >> $DeployDir/$JarDir/$ConfigFile
	echo "Xmn="$5"" >> $DeployDir/$JarDir/$ConfigFile
	echo "OtherOptions="$6"" >> $DeployDir/$JarDir/$ConfigFile
	echo "Init $1 server successfully"
}
	
function StopServer(){
	STOP_USAGE="jarctl <stop> <jar-server>"
	if [ $# -ne 1 ]; then
                echo $STOP_USAGE
                exit 1
	fi
        echo "Stop $1 server"
        pid=$(ps aux |grep "$1" |grep -v grep |grep -v sh | grep -v bash| grep -v grep | grep -v jarctl | awk '{print $2}')
        if [ ! -n "$pid" ];then
                echo "$1 has been stopped,ignore this"
        else
                kill -9 $pid > /dev/null 2>&1
                if [ $? -eq 0 ];then
                        echo "$1 stop successfully"
                else
                        echo "$1 stop failed"
                fi
        fi
}

function StartServer(){
	START_USAGE="jarctl <start> <jar-server>"
	if [ $# -ne 1 ]; then
                echo $START_USAGE
                exit 1
	fi
	JarServer=$1
        JarDir=`echo "${JarServer%.*}"`
	# check service is run
	javacount=`ps -ef|grep java|grep "$1" | grep -v grep | grep -v -E "\<bash\>" | grep -v -E "\<sh\>"|wc -l`
	if [ $javacount -ge 1 ] ; then
		echo "$1 server is running, please check"
		exit 1
	elif [ ! -f $DeployDir/$JarDir/$ConfigFile ];then
		echo "$1 server can't find the configure file, it is not init,please init server firstly"
		exit 1
	elif [ ! -f $DeployDir/$JarDir/$1 ];then
                echo "$1 server's jar package is not exist,please check it"
                exit 1
	else
		jvm_line=$(cat $DeployDir/$JarDir/$ConfigFile | grep "^Jvm")
		jvm=`echo ${jvm_line#*=}`
		port_line=$(cat $DeployDir/$JarDir/$ConfigFile | grep "^Port")
		port=`echo ${port_line#*=}`
		metaspacesize_line=$(cat $DeployDir/$JarDir/$ConfigFile | grep "^MetaspaceSize")
		metaspacesize=`echo ${metaspacesize_line#*=}`
		xmn_line=$(cat $DeployDir/$JarDir/$ConfigFile | grep "^Xmn")
		xmn=`echo ${xmn_line#*=}`
		otheroptions_line=$(cat $DeployDir/$JarDir/$ConfigFile | grep "^OtherOptions")
		otheroptions=`echo ${otheroptions_line#*=}`
		if [ -n "$jvm" ] && [ -n "$port" ];then
        		echo "starting $1 server" 
			nohup /export/servers/jdk1.8.0_192/bin/java $otheroptions -Xms$jvm -Xmx$jvm -Xmn$xmn -XX:MetaspaceSize=$metaspacesize -XX:MaxMetaspaceSize=$metaspacesize -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/export/log/$JarDir/$JarDir.hprof  -XX:ErrorFile=/export/log/$JarDir/hs_err_pid%p.log -Xloggc:/export/log/$JarDir/gc.log -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+UseG1GC -jar $DeployDir/$JarDir/$1 --server.port=$port >> /dev/null 2>&1 &
        		if [ $? -eq 0 ];then
                		echo "$1 start successfully"
        		else
                		echo "$1 start failed"
				exit 1
        		fi
		else
			echo "$1 server config file is problem,please check it"
			exit 1
		fi
	fi
}

function RestartServer(){
        RESTART_USAGE="jarctl <restart> <jar-server>"
        if [ $# -ne 1 ]; then
                echo $RESTART_USAGE
                exit 1
	fi
	StopServer $1
	StartServer $1
}

function ListServer(){
	LIST_USAGE="jarctl <list>
jarctl <list> <--all>"
        if [ $# -gt 1 ]; then
                echo "$LIST_USAGE"
                exit 1
	fi
	if [[ "$1" = "--all" ]];then
		printf "%-30s %-6s %-6s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-6s %-6s %-6s\n" ServiceName XMX XMN MSS RSS HU S1C S1U EC EU OC OU MC MU CPU PID Port Status
		for service in $DeployDir/*; do
			service_name=`echo ${service##*/}`
			JVM_PATH=$DeployDir/$service_name/config.ini
			if [[ ! -f $JVM_PATH ]];then
				continue;
			fi
			vm_xmx_line=$(cat $DeployDir/$service_name/config.ini | grep "^Jvm")
	                VM_XMX=`echo ${vm_xmx_line#*=}`
			if [[ $VM_XMX == "" ]];then
				VM_XMX="NULL"
			fi
	                port_line=$(cat $DeployDir/$service_name/config.ini | grep "^Port")
	                PORT=`echo ${port_line#*=}`
			if [[ $PORT == "" ]];then
	                        PORT="NULL"
	                fi
	                metaspacesize_line=$(cat $DeployDir/$service_name/config.ini | grep "^MetaspaceSize")
	                METSPACESIZE=`echo ${metaspacesize_line#*=}`
			if [[ $METSPACESIZE == "" ]];then
	                        METSPACESIZE="NULL"
	                fi
	                xmn_line=$(cat $DeployDir/$service_name/config.ini | grep "^Xmn")
	                XMN=`echo ${xmn_line#*=}`
			if [[ $XMN == "" ]];then
	                        XMN="NULL"
	                fi
			pid_id=$(ps aux |grep "${service_name}.jar" |grep -v grep |grep -v sh | grep -v bash| grep -v jarctl | awk '{print $2}')	
			if [ "$pid_id" = "" ];then
				printf "%-30s %-6s %-6s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-6s %-6s %-6s\n" "${service_name}.jar" $VM_XMX $XMN $METSPACESIZE NULL NULL NULL NULL NULL NULL NULL NULL NULL NULL NULL NULL $PORT STOP
				continue
			fi
			EC=$(/export/servers/jdk1.8.0_192/bin/jstat -gc $pid_id | awk 'NR==2 {print $5/1024}')
			EU=$(/export/servers/jdk1.8.0_192/bin/jstat -gc $pid_id | awk 'NR==2 {print $6/1024}')
			OC=$(/export/servers/jdk1.8.0_192/bin/jstat -gc $pid_id | awk 'NR==2 {print $7/1024}')
			OU=$(/export/servers/jdk1.8.0_192/bin/jstat -gc $pid_id | awk 'NR==2 {print $8/1024}')
			S1C=$(/export/servers/jdk1.8.0_192/bin/jstat -gc $pid_id | awk 'NR==2 {print $2/1024}')
			S1U=$(/export/servers/jdk1.8.0_192/bin/jstat -gc $pid_id | awk 'NR==2 {print $4/1024}')
			MC=$(/export/servers/jdk1.8.0_192/bin/jstat -gc $pid_id | awk 'NR==2 {print $9/1024}')
			MU=$(/export/servers/jdk1.8.0_192/bin/jstat -gc $pid_id | awk 'NR==2 {print $10/1024}')
			HU=$(/export/servers/jdk1.8.0_192/bin/jmap -heap $pid_id | grep -A4 "G1 Heap" | grep used | awk -F "=" '{print $2}' | awk '{print $1/1024/1024}')
			RSS=$(ps aux | grep "${service_name}.jar"  | grep -v grep | grep -v jarctl | awk '{print $6/1024}')	
			CPU=$(top -b -n 1  -p $pid_id |grep java|grep -v jarctl | awk '{print $9}')
			printf "%-30s %-6s %-6s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-6s %-6s %-6s\n" "${service_name}.jar" $VM_XMX $XMN $METSPACESIZE ${RSS}m ${HU}m ${S1C}m ${S1U}m ${EC}m ${EU}m ${OC}m ${OU}m ${MC}m ${MU}m ${CPU}% $pid_id $PORT RUNNING
		done
	elif [[ "$1" = "" ]];then
		printf "%-30s %-6s %-6s %-6s %-10s\n" ServiceName XMX PID Port Status
	        for service in $DeployDir/*; do
	                service_name=`echo ${service##*/}`
	                JVM_PATH=$DeployDir/$service_name/config.ini
	                if [[ ! -f $JVM_PATH ]];then
	                        continue;
	                fi
			vm_xmx_line=$(cat $DeployDir/$service_name/config.ini | grep "^Jvm")
                        VM_XMX=`echo ${vm_xmx_line#*=}`
                        if [[ $VM_XMX == "" ]];then
                                VM_XMX="NULL"
                        fi
                        port_line=$(cat $DeployDir/$service_name/config.ini | grep "^Port")
                        PORT=`echo ${port_line#*=}`
                        if [[ $PORT == "" ]];then
                                PORT="NULL"
                        fi
	                pid_id=$(ps aux |grep "${service_name}.jar" |grep -v grep |grep -v sh | grep -v bash| awk '{print $2}')
	                if [ "$pid_id" = "" ];then
	                        printf "%-30s %-6s %-6s %-6s %-10s\n" ${service_name}.jar $VM_XMX NULL $PORT STOP
	                        continue
	                fi
	                printf "%-30s %-6s %-6s %-6s %-10s\n" ${service_name}.jar $VM_XMX $pid_id $PORT RUNNING
	        done
	else
		echo "$LIST_USAGE"
		exit 1
	fi
}

function JsonServer() {
	JSON_USAGE="jarctl <json>
jarctl <json> <jar-server>"
        if [ $# -gt 1 ]; then
                echo "$JSON_USAGE"
                exit 1
        fi
	if [[ "$1" = "" ]];then
		ServiceName=$(ListServer | awk 'NR!=1 {print $1}' | sed -e s/^/'{"{#SERVICE_NAME}": "'/g -e s/'$'/'"},'/g | tr -d \\n | sed -e s/^/'{"data":['/g -e s/',$'/]}/g)
		echo $ServiceName
	else
		Value="$(ListServer --all | grep -E "\<${1}\>")"
		if [ $? -eq 0 ];then
			Key=(ServiceName XMX XMN MSS RSS HU S1C S1U EC EU OC OU MC MU CPU PID Port Status)
			num=0
			Rondom=$(cat /proc/sys/kernel/random/uuid)
			jarctl_data="/tmp/jarctl_data_`whoami`_$1_${Rondom}"
			touch ${jarctl_data}
			for i in ${Value[@]};do
				echo "${Key[$num]}:$i" >> ${jarctl_data}
				num=$(($num + 1))
			done
			pid_id=$(ps aux |grep -E "\<${1}\>" |grep -v grep |grep -v sh | grep -v bash| grep -v jarctl | awk '{print $2}')
			if [ "$pid_id" != "" ];then
				HU_UTIL=$(/export/servers/jdk1.8.0_192/bin/jmap -heap $pid_id | grep -A6 "G1 Heap" |  awk 'NR==6 {print $1}' |  sed -r 's/(.....).*/\1/g')	
				S1_UTIL=$(/export/servers/jdk1.8.0_192/bin/jstat -gcutil $pid_id | awk 'NR==2 {print $2}')
				EU_UTIL=$(/export/servers/jdk1.8.0_192/bin/jstat -gcutil $pid_id | awk 'NR==2 {print $3}')
				OU_UTIL=$(/export/servers/jdk1.8.0_192/bin/jstat -gcutil $pid_id | awk 'NR==2 {print $4}')
				MU_UTIL=$(/export/servers/jdk1.8.0_192/bin/jstat -gcutil $pid_id | awk 'NR==2 {print $3}')
				RSS_UTIL=$(top -b -n 1  -p $pid_id|grep java|awk '{print $10}')
				echo "HU_UTIL:$HU_UTIL" >> ${jarctl_data}
				echo "S1U_UTIL:$S1_UTIL" >> ${jarctl_data}
				echo "EU_UTIL:$EU_UTIL" >> ${jarctl_data}
				echo "OU_UTIL:$OU_UTIL" >> ${jarctl_data}
				echo "MU_UTIL:$MU_UTIL" >> ${jarctl_data}
				echo "RSS_UTIL:$RSS_UTIL" >> ${jarctl_data}
				cat ${jarctl_data} | sed -e s/:RUNNING$/:yes/g -e s/:STOP$/:down/g -e s/m$//g -e s/%$//g -e s/^/'"'/g -e s/'$'/'",'/g -e s/':'/'":"'/g | tr -d \\n | sed -e s/^/'{"jar_info":{'/g -e s/',$'/}}/g
				rm -rf ${jarctl_data}
			else
				echo "HU_UTIL:NULL" >> ${jarctl_data}
        	                echo "S1U_UTIL:NULL" >> ${jarctl_data}
        	                echo "EU_UTIL:NULL" >> ${jarctl_data}
        	                echo "OU_UTIL:NULL" >> ${jarctl_data}
        	                echo "MU_UTIL:NULL" >> ${jarctl_data}
        	                echo "RSS_UTIL:NULL" >> ${jarctl_data}
        	                cat ${jarctl_data} | sed -e s/:RUNNING$/:yes/g -e s/:STOP$/:down/g -e s/:NULL$/:-1/g -e s/m$//g -e s/%$//g -e s/^/'"'/g -e s/'$'/'",'/g -e s/':'/'":"'/g | tr -d \\n | sed -e s/^/'{"jar_info":{'/g -e s/',$'/}}/g
				rm -rf ${jarctl_data}
			fi
		else
			exit 1
		fi	
	fi
}

function JstatServer() {
	JSTAT_USAGE="Usage: jarctl /export/servers/jdk1.8.0_192/bin/jstat <-h>
       jarctl /export/servers/jdk1.8.0_192/bin/jstat <-options>
       jarctl /export/servers/jdk1.8.0_192/bin/jstat <option> <pid> [<interval-time> ms] <count>"
	 if [ $# -gt 4 ]; then
                echo "$JSTAT_USAGE"
                exit 1
        fi
	SELF_USAGE="Usage:/export/servers/jdk1.8.0_192/bin/jstat -h|-options
/export/servers/jdk1.8.0_192/bin/jstat [-<option>] [<pid>] [<interval-time> ms] [<count>]
Definitions:
	   <option>: -gc | -class | -gccause | -gcutil | -gcpermcapacity | -gccapacity 
           -gcnew | -gcnewcapacity | -gcold | -gcoldcapacity 
           -compiler | -printcompilation
           default -gc
	   <pid>:this server process id
      	   <interval-time>: Sampling interval The following forms are allowed:
      	       <n>['ms']
           Where <n> is an integer and the suffix specifies the units as milliseconds('ms') . 
           The default units are 'ms'."
	#process ID
	OPTION=$1
	PID=$2
	#time interval util:ms
	TIME=$3
	COUNT=$4
	OPTION_ARRA=("class" "compiler" "gc" "gccapacity" "gccause" "gcmetacapacity" "gcnew" "gcnewcapacity" "gcold" "gcoldcapacity" "gcutil" "printcompilation")
	if [ "$OPTION" ];then
		if [ ${OPTION} = "-h" ];then
			echo "$SELF_USAGE"
		elif [ ${OPTION} = "-options" ];then
			echo "All of option is below:
-class
-compiler
-gc
-gccapacity
-gccause
-gcmetacapacity
-gcnew
-gcnewcapacity
-gcold
-gcoldcapacity
-gcutil
-printcompilation"
		elif echo ${OPTION_ARRA[@]} | grep -w -e  "${OPTION:1}" >> /dev/null 2>&1;then
        		if [ "$PID" ];then
				case x$PID in
					x[0-9]*)
        				;;
        				*)
                				echo "Please input a correct pid num that find by the command <jarctl list>!"
                				exit 1
        				;;
        			esac
			else
				echo "Please input a correct pid num that find by the command <jarctl list>!"
				exit 1
			fi
        		if [ "$TIME" ];then
                		case x$TIME in
                			x[0-9]*)
                			;;
                 			*)
                        			echo "Please input a correct time that must be a num!"
                        			exit 1
                			;;
                		esac
			fi
 		        if [ "$COUNT" ];then
                		case x$COUNT in
                			x[0-9]*)
                 			;;
                			*)
                        			echo "Please input a correct count that must be a num!"
                        			exit 1
                			;;
                		esac
        		fi
			/export/servers/jdk1.8.0_192/bin/jstat $OPTION $PID $TIME $COUNT
		else
			echo "$JSTAT_USAGE"
			exit 1
		fi
	else
		echo "$JSTAT_USAGE"
		exit 1   
	fi

}

function JudgePara() {
	PARA=$1
        PARA=`echo ${PARA##*.}`
        if [ "$PARA" != "jar" ];then
       		echo "the second parameter must be end with the "jar", example:"test.jar""
                exit 1
        fi
}

function Main() {
	case $1 in
		-h|--help)
			echo "$USAGE"
		;;
        	init)
			JudgePara $2
			InitServer $2 $3 $4 $5 $6 "$7"
        	;;
		stop)
			JudgePara $2
                	StopServer $2 $3
		;;
		start)
			JudgePara $2
                	StartServer $2 $3
		;;
		restart)
			JudgePara $2
                	RestartServer $2 $3
        	;;
		list)
			ListServer $2 $3
		;;
		jstat)
			JstatServer $2 $3 $4 $5 $6
		;;
		json)   
			JsonServer $2 $3
		;;
        	*)
      			echo "$USAGE"  
        	;;
	esac
}

#main function
if [ $# -lt 1 ]; then
	echo "$USAGE"
	exit 1
else
	Main "$@"
fi
