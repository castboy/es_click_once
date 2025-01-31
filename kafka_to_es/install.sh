#!/bin/bash

MYDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

function init_log() {
    LOG_DIR="${MYDIR}/install_log"

    if [ -z $(ls ${MYDIR} | sed -n '/install_log/p') ]
    then
        mkdir $LOG_DIR
    fi

	INSTALL_LOG="$LOG_DIR/$(date '+%G-%m-%d_%H:%M:%S').log"
}

function log() {
	if [ -z $2 ]
	then
		echo "$(date '+%G-%m-%d %H:%M:%S'): INF   detail: $1"  >> $INSTALL_LOG
	else
		echo "$(date '+%G-%m-%d %H:%M:%S'): CRT   detail: $1" >> $INSTALL_LOG 
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

function init_vars() {
	APT_HOME=$(env_var "${APT_HOME}" "get env_var APT_HOME")
	KAFKA_TO_ES_PKG="$APT_HOME/package/kafka_to_es"
	CONF_FILE="$KAFKA_TO_ES_PKG/conf/conf.ini"
}

function mv_install_pkg() {
	if [ "" != "$(ls $APT_HOME/package | sed -n '/kafka_to_es/p')" ]
	then
		rm $KAFKA_TO_ES_PKG -rf
		log "rm kafka_to_es in dest dir"
	fi
	
	mkdir $KAFKA_TO_ES_PKG
	cp ${MYDIR}/kafka_to_es.tgz $KAFKA_TO_ES_PKG -r
	cd $KAFKA_TO_ES_PKG
	tar xzvf kafka_to_es.tgz 1>/dev/null
        rm kafka_to_es.tgz -f
	
	log "put kafka_to_es pkg in dest dir"
}

function conf_file() {
	partitionSet=0
    	kafka_brokers=$(apt_config_show kafka brokers)
	#kafka_brokers="192.168.1.11;192.168.1.12;192.168.1.13"
	kafka_brokers=$(echo $kafka_brokers | sed 's/;/,/g')
	
	es_nodes=$(apt_show_app es nodes)
	#es_nodes="10.88.1.102;10.88.1.103"
	es_nodes=$(echo $es_nodes | sed 's/;/,/g')
	es_port=9200
	
	echo " " > $CONF_FILE
	
	sed -i '1i [topic] \
vds-alert = '$partitionSet' \
waf-alert = '$partitionSet' \
ids-alert = '$partitionSet' \
\
[kafka] \
brokers = '$kafka_brokers' \
start = \
\
[elasticsearch] \
nodes = '$es_nodes' \
port = '$es_port'' $CONF_FILE	
}

function mv_kafka_to_es() {
	cp "$KAFKA_TO_ES_PKG/kafka_to_es" ${APT_INITD}
} 

init_log
init_vars
mv_install_pkg
conf_file
mv_kafka_to_es
