#!/bin/bash

function init_vars() {
	APT_HOME=$(env_var "${APT_HOME}" "get env_var APT_HOME")
	ES_PKG=$APT_HOME/package/es
	JAVA8_PKG=$ES_PKG/jdk-8u132-linux-x64.tar.gz
	ES_HOME=$ES_PKG/elasticsearch-5.2.2
	ES_BIN=$ES_HOME/bin/elasticsearch
	ES_CONFIG=$ES_HOME/config/elasticsearch.yml
	INSTALL_LOG=install.log	
}

function mv_install_pkg() {
	if [ "" != $(ls $ES_PKG | sed -n '/es/p') ]
	then
		rm $ES_PKG -rf
		log "clear ES_PKG dir"
	fi
	
	mkdir $ES_PKG
	cp ./es.tgz $ES_PKG -r
	cd $ES_PKG
	tar xzvf es.tgz
	
	log "mv install pkg exed"
}

function insure_java8() {
	if ["8" != $(javac -version 2>&1 | awk '{print $2}' | awk -F '.' '{print $2}')]
	then
		java8_pkg $JAVA8_PKG
		java8_guide $ES_BIN
	fi	
}

function add_user_es() {
	useradd -d /home/es -m es
	echo "es.123" | passwd --stdin es
	chown -R es:es $ES_HOME	
}

function es_config_file() {
	hostNode=$(env_var "${THIS_HOST}" "get env_var THIS_HOST")
	allNodes=$(env_var "$(apt_show_app eleacsearch)" "get all es nodes")
	${APT_HOME}/package/es/es_yml -hostNode=hostNode -allNodes=allNodes
	mv elasticsearch.yml $ES_CONFIG -f	
}

function max_num_of_threads() {
	if ["" = $(cat /etc/security/limits.conf | sed -n '/es soft nproc 4096/p')]
	then
		sed -i '$a es soft nproc 4096\es hard nproc 4096' /etc/security/limits.conf
		log "set max number of threads"
	else
		log "have set max number of threads before"
	fi	
}

function max_virtu_mem() {
	if ["" = $(cat /etc/sysctl.conf | sed -n '/vm.max_map_count/p')]
	then
		echo "vm.max_map_count=262144" >> /etc/sysctl.conf
		log "set max virtual memory"
	else
		sed -i 's/vm.max_map_count=.*/vm.max_map_count=262144/'
		log "update max virtual memory"
	fi	
}

function max_file_descs() {
	if ["" = $(nl /etc/security/limits.conf | sed -n '/es hard nofile 65536/p')]
	then
		sed -i '$a es hard nofile 65536\es soft nofile 65536' /etc/security/limits.conf
		log "set max file descriptors"
	else
		log "have set max file descriptors before"
	fi	
}


function mem_lock() {
	if ["" = $(nl /etc/security/limits.conf | sed -n '/es soft memlock unlimited/p')]
	then
		sed -i '$a es soft memlock unlimited\es hard memlock unlimited' /etc/security/limits.conf
		log "set memory locking"
	else
		log "have set memory locking before"
	fi	
}


java8_guide(){
	if ["" = $(cat $1 | sed -n '/JAVA_HOME/p')]
	then
		log "set java8_guide"
		sed -i '1i export JAVA_HOME=/opt/tool/jdk \
		export PATH=$JAVA_HOME/bin:$PATH \
		export CLASSPATH=.:$JAVA_HOME/lib.dt.jar:$JAVA_HOME/lib/tools.jar \
		export JRE_HOME=$JAVA_HOME/jre' $1
	else
		log "hava set java8_guide before, skip set java8_guide"
	fi
}

java8_pkg(){
	log "put java8_pkg"
	tar zxvf $1 -C /opt/tool
	mv $(ls | sed '/jdk.*/p') jdk
}

log() {
	if [ -z $2 ]
	then
		echo $(date "+%G-%m-%d %H:%M:%S")": INF   detail: $1" >> $LOG_FILE
	else
		echo $(date "+%G-%m-%d %H:%M:%S")": CRT   detail: $1" >> $LOG_FILE
		exit 1
	fi
}

env_var() {
	var=$1
	if [ -z $1 ]
	then
		log "$2 failed" "c"
	else
		log "$2 success" 
		echo "$var"
	fi
}


init_vars
mv_install_pkg
insure_java8
add_user_es
es_config_file
max_num_of_threads
max_virtu_mem
max_file_descs
mem_lock

