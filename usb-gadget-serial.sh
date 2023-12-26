#!/bin/sh
# $1: -d - tear down

#FUNCS=("acm.usb0" "ncm.usb0" "acm.usb1")
#FUNCS=("acm.usb0" "acm.usb1")

CFS=/sys/kernel/config/usb_gadget
VID="0x1d6d"
PID="0x0104"
LANG="0x409"

init()
{
	#zcat /proc/config.gz | grep 'CONFIGFS_FS=' > /dev/null || exit 1
	lsmod | grep libcomposite > /dev/null || modprobe libcomposite || exit 2
	mount | grep configfs > /devnull || 
		mount -t configfs none $(dirname $CFS) || exit 3
}

create_gadget()
{
	[ ! -d ${CFS}/g1 ] || exit 5
	mkdir ${CFS}/g1 && cd ${CFS}/g1 || exit 6
	echo "$VID" > idVendor
	echo "$PID" > idProduct

	mkdir strings/$LANG
	echo "0123456789" > strings/$LANG/serialnumber
	echo "Foo Inc" > strings/$LANG/manufacturer
	echo "Bar gadget" > strings/$LANG/product
}

# configuraton naming: configs/<name>.<number>
create_config()
{
	[ -d ${CFS}/g1 ] && cd ${CFS}/g1 || exit 5
	mkdir configs/c.1
	mkdir configs/c.1/strings/$LANG
	echo "conf1" > configs/c.1/strings/$LANG/configuration
}

# $1 - function name
# function naming: functions/<name>.<instance_name>
create_func_single()
{
	local _func=$1

	mkdir functions/${_func} || return
	ln -s functions/${_func} configs/c.1
}

activate()
{
	local _udc

	_udc=$(ls /sys/class/udc/)
	# TODO check $_udc
	echo "$_udc" > UDC
}

teardown()
{
	local _ent

	[ -d ${CFS}/g1 ] && cd ${CFS}/g1 || exit 5
	echo "" > UDC
	for _ent in $(ls configs/c.1/); do
		[[ "$_ent" != "MaxPower" ]] || continue
		[[ "$_ent" != "bmAttributes" ]] || continue
		[[ "$_ent" != "strings" ]] || continue
		rm -f configs/c.1/$_ent
		rmdir functions/$_ent
	done
	rmdir configs/c.1/strings/$LANG
	rmdir configs/c.1
	rmdir strings/$LANG
	cd .. && rmdir g1
	echo "toredown"
}

### MAIN ###

[ "$1" != "-d" ] || { teardown; exit 0; }

init
create_gadget
create_config

#for func in ${FUNCS[*]}; do
#	create_func_single $func
#done

create_func_single acm.usb0
create_func_single acm.usb1

activate
echo created

