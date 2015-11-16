#!/bin/sh


source /etc/profile

function mrxtext() {
echo -e "\33[1;33m$@\33[m"
}

function mrxtext2() {
echo -e "\33[1;32m$@\33[m"
}


function mrx_boot() {

mrxtext "remountar em rw"
mount -n -v -o remount,rw /

mrxtext "atualizar /etc/mtab"
rm -f /etc/mtab

>/etc/mtab

mount -f /

mrxtext "montar sistemas para o kernel"
mount -v /proc
mount -v /proc/bus/usb
mount -v /sys
mkdir -p /dev/shm
mkdir -p /dev/pts
mount -v /dev/shm
mount -v /dev/pts

mrxtext "configurar hotplug como udev"
echo "/sbin/udev" > /proc/sys/kernel/hotplug

mrxtext "popular /dev"
udevstart

mrxtext "atualiza modulos"
mkdir -p /lib/modules/`uname -r`
depmod -a

mrxtext "configurar hostname"
hostname ramdisk-`cat /proc/sys/kernel/random/boot_id | cut -f1 -d "-"`.invalid

mrxtext "rede loop"
ifconfig lo 127.0.0.1 

mrxtext "Espere DHCP (10 segundos no maximo)......."
dhcpcd -t 10 -h `hostname`

mrxtext "iniciando servidor SSH"
sshd

mrxtext "iniciando servidor APACHE + PHP + SQLITE + MYSQL"
httpd

mrxtext "SERVIDOR no IP:"
ifconfig eth0  | grep "inet " | cut -f2 -d ":" | cut -f1 -d " "

printf "\n\n"

mrxtext "iniciar syslogd e klogd"
echo "*.* /dev/tty5" > /etc/syslog.conf
syslogd
klogd

mrxtext "todos campos exp:\c" ; mrxtext2 "* \c" ; mrxtext "valor:\c" ; mrxtext2 "100%"
numids=`amixer controls | cut -f1 -d "," | cut -f2 -d "="`
for numid in $numids ; do
    amixer cset numid=$numid 100% &> /dev/null
done


mrxtext "todos campos exp:\c" ; mrxtext2 "*As* \c" ; mrxtext "valor:\c" ; mrxtext2 "0"
numids=`amixer controls | grep "As" | cut -f1 -d "," | cut -f2 -d "="`
for numid in $numids ; do
    amixer cset numid=$numid 0 &> /dev/null
done

mrxtext "todos campos exp:\c" ; mrxtext2 "*Mic Select*\c " ; mrxtext "valor:\c" ; mrxtext2 "0"
numids=`amixer controls | grep "Mic Select" | cut -f1 -d "," | cut -f2 -d "="`
for numid in $numids ; do
    amixer cset numid=$numid 0 &> /dev/null
done

}

function mrx_down() {

mrxtext "matar todos coml: SIGNAL TERM"
killall5 -15

mrxtext "matar todos com: SIGNAL KILL"
killall5 -9

mrxtext "desmontado todos sistemas de arquivos"
umount -a -d -r -v

}

function mrx_halt() {
mrx_down
mrxtext  "desligando...  "
halt -p
}

function mrx_reboot() {
mrx_down
mrxtext  "reinicando..."
reboot
}

case $1 in 
0) mrx_halt ;;
1) mrx_boot ;;
2) mrx_boot ;;
3) mrx_boot ;;
4) mrx_boot ;;
5) mrx_boot ;;
6) mrx_reboot ;;
esac



