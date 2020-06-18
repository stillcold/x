#!/bin/bash

cd `dirname $0`
pwd
cd ..

pid=`ps -ef | grep x |grep basestation| grep slave |grep -v color |grep -v grep |grep -v nginx | awk '{print $2}'`

if [ "${pid}" = "" ]
then
	echo "no slave basestation is alive"
else
	kill -9 ${pid}
fi

# nohup ./x process/basestation/slave/entry.config > log/todo.log 2>&1 &
./x process/basestation/slave/entry.config
