#!/bin/bash

cd `dirname $0`
pwd
cd ..

pid=`ps -ef | grep one | grep x |grep -v color |grep -v grep | awk '{print $2}'`

echo "search service pid is ${pid}"


if [ "${pid}" = "" ]
then
	echo "no javasearch alive"
else
	kill -9 ${pid}
fi


nohup ./x process/one/entry.config &

