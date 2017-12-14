#/bin/bash
  . /etc/profile
  ${APT_HOME}/package/agent/conf
  Apthome=${APT_HOME}
  App="agent"
  case $1 in
     "start")
    echo $$ > ${APT_PID_FILE}/${App}.pid
    cd ${Apthome}/package/${App}
    exec 2>&1 ./apt_agent
    ;;
      "stop")
    kill `cat /var/run/${App}.pid`;;
    restart)
        ;;
esac
exit 0