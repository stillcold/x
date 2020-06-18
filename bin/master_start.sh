#!/bin/bash

cd `dirname $0`
pwd
cd ..

pid=`ps -ef | grep x |grep basestation| grep master |grep -v color |grep -v grep |grep -v nginx | awk '{print $2}'`

if [ "${pid}" = "" ]
then
	echo "no master basestation is alive"
else
	kill -9 ${pid}
fi

# nohup ./x process/basestation/master/entry.config > log/todo.log 2>&1 &
./x process/basestation/master/entry.config
