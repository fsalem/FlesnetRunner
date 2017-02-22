#!/bin/bash

ifconfig ib0 | grep 'inet addr:' | cut -d: -f2 | sort -k1 -n | awk '{ print $1}'