#!/bin/bash
# This code is under Simplified BSD License, see LICENSE for more info.
# Copyright (c) 2010, Piotr Karbowski <jabberuser@gmail.com>.
# All rights reserved.
#
# You need working bash, tee and coretemp (kernel module) to run this script.
# Designed for hp compaq 6510b and similar.
#
## Big thanks to #bash (mostly for prince_jammys user) at freenode for help with this script.

####
## config.
####
workdir="$(readlink -f $(dirname $0))"
if [[ -f "$workdir/config" ]]; then
	. $workdir/config
elif [[ -f "/etc/hpc_fanctl.conf" ]]; then
	. /etc/hpc_fanctl.conf
else
	echo "You need config file. Exiting..."
	exit 1
fi

####
## code.
####
if [[ $UID != 0 ]]; then
	echo "You need root to run this script."
	exit 1
fi

get_temp() {
	# It depends on coretemp module for lm_sensors, using thermal_zone isn't good
	# on newer kernels it refreshing with (too) big delay.
	# It will operate on average temperature from both core, best idea so far.

	# get temp for both core, first 2 chars.
	coretemp_temp0="$(cut -c1-2 /sys/bus/platform/devices/coretemp.0/temp1_input)"
	coretemp_temp1="$(cut -c1-2 /sys/bus/platform/devices/coretemp.1/temp1_input)"
	
	# get avg temp +1'C, for safe.
	#cpu_temp=" $(( ($coretemp_temp0+$coretemp_temp1)/2+1  )) "
	cpu_temp=" $(( ($coretemp_temp0+$coretemp_temp1)/2  )) "
}

set_fan() {
case $1 in
	1)
		echo 0 > ${fanpath[1]}
		tee ${fanpath[@]:2:5} <<<3 >/dev/null
	;;

	2)
		tee ${fanpath[@]:1:2} <<<0 >/dev/null
		tee ${fanpath[@]:3:5} <<<3 >/dev/null
	;;

	3)
		tee ${fanpath[@]:1:3} <<<0 >/dev/null
		tee ${fanpath[@]:4:5} <<<3 >/dev/null
	;;

	4)
		tee ${fanpath[@]:1:4} <<<0 >/dev/null
		echo 3 > ${fanpath[5]}
	
	;;
	
	5)
		tee ${fanpath[@]:1:5} <<<0 >/dev/null
	;;

	0)
		tee ${fanpath[@]:1:5} <<<3 >/dev/null
	;;
esac
}

while true; do
	get_temp

	if   [ $cpu_temp -lt $temp1 ]; then fanlevel=0;
	elif [ $cpu_temp -lt $temp2 ]; then fanlevel=1;
	elif [ $cpu_temp -lt $temp3 ]; then fanlevel=2;
	elif [ $cpu_temp -lt $temp4 ]; then fanlevel=3;
	elif [ $cpu_temp -lt $temp5 ]; then fanlevel=4;
	elif [ $cpu_temp -ge $temp5 ]; then fanlevel=5;
	fi

	set_fan $fanlevel
	sleep $interval
done
