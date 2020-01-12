#!/bin/bash

cd `dirname $0`
pwd
cd ..

pid=`ps -ef | grep x | grep todo |grep -v color |grep -v grep | awk '{print $2}'`

if [ "${pid}" = "" ]
then
	echo "no todo is alive"
else
	kill -9 ${pid}
fi

nohup ./x process/todolist/entry.config > log/todo.log 2>&1 &
