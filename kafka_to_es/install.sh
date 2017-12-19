#!bin/bash

function log() {
	if [ -z $2 ]
	then
		echo $(date "+%G-%m-%d %H:%M:%S")": INF   detail: $1" >> $INSTALL_LOG
	else
		echo $(date "+%G-%m-%d %H:%M:%S")": CRT   detail: $1" >> $INSTALL_LOG
		exit 1
	fi
}

function log_file() {
	INSTALL_LOG="$LOG_DIR/install-$(date "+%G-%m-%d_%H:%M:%S").log"
	touch $INSTALL_LOG
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

function init_vars() {
	APT_HOME= $(env_var "${APT_HOME}" "get env_var APT_HOME")
	KAFKA_TO_ES_PKG="$APT_HOME/package/kafka_to_es"
	CONF_FILE="$KAFKA_TO_ES_PKG/conf/conf.ini"
	LOG_DIR="$KAFKA_TO_ES_PKG/log"
}

function mv_install_pkg() {
	if [ "" != "$(ls $APT_HOME/package | sed -n '/kafka_to_es/p')" ]
	then
		rm $KAFKA_TO_ES_PKG -rf
		log "rm es_pkg in dest dir"
	fi
	
	mkdir $KAFKA_TO_ES_PKG
	cp ./kafka_to_es.tgz $KAFKA_TO_ES_PKG -r
	cd $KAFKA_TO_ES_PKG
	tar xzvf kafka_to_es.tgz 1>/dev/null
	
	log "put kafka_to_es pkg in dest dir"
}

function conf_file() {
	partitionSet=0,1,2,3
	
	nodes=192.168.1.103,192.168.1.102
	port=9200
	
	echo " " > $CONF_FILE
	
	sed -i '1i [topic] \
vds-alert = '$partitionSet' \
waf-alert = '$partitionSet' \
ids-alert = '$partitionSet' \
\
[kafka] \
brokers = '$kafka-brokers' \
start = \
\
[elasticsearch] \
nodes = '$nodes' \
port = '$port'' $CONF_FILE	
}

init_vars
log_file
mv_install_pkg
conf_file