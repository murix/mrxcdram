#!/bin/bash

source version.sh

function echo_ok(){
    echo -e "\033[A\033[40G\033[1;32mOK\033[m"
}

function echo_erro(){
    echo -e "\033[A\033[40G\033[1;5;37;41mERRO\033[m"
}

function mrxoutcode(){
    if [ "$?" == "0" ]; then
	echo_ok;
    else
	echo_erro;
    fi
}

function mrxtext() {
echo -e "\033[01;33m$@\033[m"
}


mrxtext "################################################################"
mrxtext "# MURIX ramdisk maker $VERSION"
mrxtext "# Create by Murilo Pontes [murilopontes@users.sourceforge.net] #"
mrxtext "################################################################"

export MNT="/tmp/ramdisk_temp"
export CMDLIST="ramdisk.db"
export DEPLIST="/tmp/ramdisk_list"
export RAMIMAGE="/tmp/ramdisk_image.cpio.gz"


mrxtext "desmontar loop se ocupado"
pidof $LOOPDEV &> /dev/null
if [ $? == 0 ] ; then
    losetup -d /dev/$LOOPDEV
    mrxoutcode
fi

mrxtext "limpar tempario"
rm -rf $MNT
rm -rf $RAMIMAGE
rm -rf $DEPLIST



mrxtext "criar nova raiz temporaria"
mkdir -p $MNT/{INSTALAR_ORIGEM,INSTALAR_DESTINO}
mkdir -p $MNT/bin
mkdir -p $MNT/dev
mkdir -p $MNT/etc/{apache,ssh}
mkdir -p $MNT/lib
mkdir -p $MNT/mnt/{floppy,cdrom}
mkdir -p $MNT/sys
mkdir -p $MNT/proc
mkdir -p $MNT/share/{alsa,terminfo/{l,x}}
mkdir -p $MNT/var/lib/dhcpc
mkdir -p $MNT/var/{run,log,empty}
mkdir -p $MNT/tmp
mkdir -p $MNT/www
cp share/devfsd.conf 		$MNT/etc
cp share/initscript 		$MNT/etc
cp share/inittab 		$MNT/etc
cp share/murix.sh 		$MNT/etc
cp share/profile		$MNT/etc
cp share/passwd               	$MNT/etc
cp share/group          	$MNT/etc
cp share/fstab          	$MNT/etc
cp share/nsswitch.conf         	$MNT/etc
cp share/hosts          	$MNT/etc
cp share/apache/httpd.conf     	$MNT/etc/apache
cp share/apache/mime.types     	$MNT/etc/apache
cp README			$MNT
cp COPYING			$MNT
ln -s . 			$MNT/usr
ln -s bin 			$MNT/sbin
ln -s bash 			$MNT/bin/sh
ln -s mc 			$MNT/bin/mcedit
touch                   	$MNT/etc/mtab
#para o alsamixer
cp    /usr/share/alsa/alsa.conf        	$MNT/share/alsa
#udev
cp -a /etc/udev/			$MNT/etc/
#ssh
cp -a /etc/ssh/*			$MNT/etc/ssh
#php para apache
cp -a /usr/lib/apache/*.so		$MNT/lib
#nss da glibc
cp -a /lib/libnss_*so*			$MNT/lib
#termcap para mc
cp    /usr/share/terminfo/l/linux 	$MNT/share/terminfo/l
cp    /usr/share/terminfo/x/xterm-color $MNT/share/terminfo/x
#usados pelos programas de rede
cp    /etc/{protocols,services,rpc} 	$MNT/etc
#plugins do ettercap
cp /usr/etc/etter.conf			$MNT/etc
cp -a /usr/lib/ettercap/*.so 		$MNT/lib
cp -a /usr/share/ettercap 		$MNT/share


mrxtext "copiar comandos"
for comando in `cat $CMDLIST | grep -v "#"` ; do 
    lugar=`which $comando`
    cp $lugar $MNT/bin/$comando
done


printf '
if [ -x $1 ] && [ ! -d $1 ]; then 
    ldd $1 | grep -v "warning:" | grep -v "not a dynamic executable" | tr -d [:blank:] | cut -f1 -d "(" | cut -f2 -d ">" >> %s ; 
fi
' "$DEPLIST" > /tmp/extract.sh

chmod 755 /tmp/extract.sh


mrxtext "procurando por bibliotecas necessarias"
find $MNT -exec /tmp/extract.sh '{}' ';'

mrxtext "copiar bibliotecas"
for lib in `cat $DEPLIST | sort | uniq` ; do
    cp $lib $MNT/lib/`basename $lib`
done

mrxtext "tirar simbolos de depuracao em $MNT/lib"
find $MNT/lib -exec strip -pg '{}' ';'

mrxtext "tirar todos os simbolos em $MNT/bin"
find $MNT/bin -exec strip -ps '{}' ';'

mrxtext "set permissions"
chmod -R 755 $MNT/{bin,lib}
chmod 4755   $MNT/bin/mplayer


mrxtext "criar links ocultos"
ln -s /etc/profile 	$MNT/.bashrc
ln -s /etc/profile 	$MNT/.profile
ln -s /bin/bash 	$MNT/init


mknod -m 600 $MNT/dev/console c 5 1 
mknod -m 666 $MNT/dev/null c 1 3    

cd $MNT
find . | cpio -H newc -o | gzip > $RAMIMAGE

if [ -f /boot/ramdisk.gz  ] ; then
    mrxtext "fazer backup da imagem atual"
    mv -v /boot/ramdisk.gz /boot/ramdisk-backup-`date +%F-%T`.gz
fi

mrxtext "instalar a nova imagem"
mv -v $RAMIMAGE /boot/ramdisk.gz

mrxtext "ajuste no seu carregador de boot o tamanho do ramdisk para $tamanho"



#EOF

