#!/bin/bash

function log_file() {
	INSTALL_LOG="$(pwd)/install-$(date "+%G-%m-%d_%H:%M:%S").log"
	touch $INSTALL_LOG
}

function init_vars() {
	APT_HOME=$(env_var "${APT_HOME}" "get env_var APT_HOME")
	ES_PKG=$APT_HOME/package/es
	JAVA8_PKG=$ES_PKG/jdk1.8.0_131
	ES_HOME=$ES_PKG/elasticsearch-5.2.2
	ES_BIN=$ES_HOME/bin/elasticsearch
	ES_CONFIG=$ES_HOME/config/elasticsearch.yml
}

function mv_install_pkg() {
	if [ "" != "$(ls $APT_HOME/package | sed -n '/es/p')" ]
	then
		rm $ES_PKG -rf
		log "rm es_pkg in dest dir"
	fi
	
	mkdir $ES_PKG
	cp ./es.tgz $ES_PKG -r
	cd $ES_PKG
	tar xzvf es.tgz 1>/dev/null
	
	log "put es_pkg in dest dir"
}

function insure_java8() {
	if [ "8" != "$(java -version 2>&1 | awk '{print $2}' | awk -F '.' '{print $2}')" ]
	then	
		put_java8_in
		java8_guide $ES_BIN
	fi
}

function add_user_es() {
	if [ -z "$(cat /etc/passwd | sed -n '/^es.*\/home\/es/p')" ]
	then
		useradd -d /home/es -m es
		echo "es.123" | passwd --stdin es
		chown -R es:es $ES_HOME
		log "add user es and chown"
	else
		chown -R es:es $ES_HOME
		log "es user already exist, chown only"
	fi
}

function es_config_file() {
	hostNode=$(env_var "${THIS_HOST}" "get env_var THIS_HOST")
	#allNodes=$(env_var "$(apt_show_app eleacsearch)" "get all es nodes")
	allNodes=$(env_var "${ES_NODES}" "get all es nodes")
	${APT_HOME}/package/es/es_yml -esHome=$ES_HOME -hostNode=$hostNode -allNodes=$allNodes 
	mv elasticsearch.yml $ES_CONFIG -f	
}


function max_num_of_threads() {
	if [ -z "$(cat /etc/security/limits.conf | sed -n '/es soft nproc 4096/p')" ]
	then
		sed -i '$a es soft nproc 4096\
                   es hard nproc 4096' /etc/security/limits.conf #use space not table, not the case, `sed -i 's/^[" "]*//' /etc/security/limits.conf` may not effect
		sed -i 's/^[" "]*//' /etc/security/limits.conf
		log "set max number of threads"
	else
		log "have set max number of threads before"
	fi	
}

function max_virtu_mem() {
	if [ -z "$(cat /etc/sysctl.conf | sed -n '/vm.max_map_count/p')" ]
	then
		echo "vm.max_map_count=262144" >> /etc/sysctl.conf
		log "set max virtual memory"
	else
		sed -i 's/vm.max_map_count=.*/vm.max_map_count=262144/' /etc/sysctl.conf
		log "update max virtual memory"
	fi	
}

function max_file_descs() {
	if [ -z "$(nl /etc/security/limits.conf | sed -n '/es hard nofile 65536/p')" ]
	then
		sed -i '$a es hard nofile 65536\
                   es soft nofile 65536' /etc/security/limits.conf
		sed -i 's/^[" "]*//' /etc/security/limits.conf
		log "set max file descriptors"
	else
		log "have set max file descriptors before"
	fi	
}


function mem_lock() {
	if [ -z "$(nl /etc/security/limits.conf | sed -n '/es soft memlock unlimited/p')" ]
	then
		sed -i '$a es soft memlock unlimited\ 
                   es hard memlock unlimited' /etc/security/limits.conf
		sed -i 's/^[" "]*//' /etc/security/limits.conf
		log "set memory locking"
	else
		log "have set memory locking before"
	fi	
}

function put_java8_in(){
	ln -s $JAVA8_PKG /opt/tool/jdk
	log "java version is not java8, put java8_pkg in"	
}

function java8_guide(){
	if [ -z "$(cat $1 | sed -n '/\/opt\/tool\/jdk/p')" ]
	then
		sed -i '1a export JAVA_HOME=/opt/tool/jdk\
export PATH=$JAVA_HOME/bin:$PATH\
export CLASSPATH=.:$JAVA_HOME/lib.dt.jar:$JAVA_HOME/lib/tools.jar\
export JRE_HOME=$JAVA_HOME/jre' $1
		log "set java8_guide for es"
	else
		log "hava set java8_guide before, skip set java8_guide"
	fi
}

function log() {
	if [ -z $2 ]
	then
		echo $(date "+%G-%m-%d %H:%M:%S")": INF   detail: $1" >> $INSTALL_LOG
	else
		echo $(date "+%G-%m-%d %H:%M:%S")": CRT   detail: $1" >> $INSTALL_LOG
		exit 1
	fi
}

function env_var() {
	var=$1
	if [ -z $1 ]
	then
		log "$2 failed" "c"
	else
		log "$2 success" 
		echo "$var"
	fi
}




log_file
init_vars
mv_install_pkg
insure_java8
add_user_es
es_config_file
max_num_of_threads
max_virtu_mem
max_file_descs
mem_lock

