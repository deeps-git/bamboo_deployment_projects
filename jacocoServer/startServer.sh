#!/bin/sh

JAVA_HOME=/usr/java/latest

$JAVA_HOME/bin/java $* com.comcast.xcal.xbo.tools.JacocoDataServer &

pid=$!

echo $pid > agent.pid
