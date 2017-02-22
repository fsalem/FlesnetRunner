#!/bin/bash

ALPS=$(env|grep "ALPS_APP_PE")
IFS='=' read -ra array <<< "$ALPS"

HOSTNAME=$(hostname)
echo "$[array[1]] $HOSTNAME"