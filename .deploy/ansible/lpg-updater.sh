#!/bin/bash
### BEGIN INIT INFO
# Provides:          lpg-updater.sh
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Updater
# Description:       Update LPG repository on system startup
### END INIT INFO

PROJECT_PATH="/vagrant"
PYTHON="/home/vagrant/lpg-env/bin/python"
MANAGE="$PYTHON $PROJECT_PATH/manage.py"

function Update_On_Start() {
    supervisorctl restart all
}


case "$1" in
start)
    Update_On_Start;
    ;;
stop)
    echo "Not implemented";
    ;;
restart)
    echo "Not implemented";
    ;;
*)
    echo "Error options"
esac
