#!/bin/bash
grep "include" ../../settings.gradle | grep -v "//" | sed 's/include//g' | sed "s/'//g"
