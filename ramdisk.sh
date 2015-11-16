#!/bin/sh

source version.sh

function echo_ok(){
    echo -e "\33[A\33[40G\33[1;32mOK\33[m"
}

function echo_erro(){
    echo -e "\33[A\33[40G\33[1;5;37;41mERRO\33[m"
}

function mrxoutcode(){
    if [ "$?" == "0" ]; then
	echo_ok;
    else
	echo_erro;
    fi
}

function mrxtext() {
echo -e "\33[01;33m$@\33[m"
}


mrxtext "################################################################"
mrxtext "# MURIX ramdisk maker $VERSION"
mrxtext "# Create by Murilo Pontes [murilopontes@users.sourceforge.net] #"
mrxtext "################################################################"

export MNT="/tmp/ramdisk_temp"
export CMDLIST="ramdisk.db"
export DEPLIST="/tmp/ramdisk_list"
export RAMIMAGE="/tmp/ramdisk_image"
export RAMMOUNTDIR="/tmp/ramdisk_mountdir"
export LOOPDEV="loop3"
export FOLGA_EM_KB="2000"


mrxtext "desmontar loop se ocupado"
pidof $LOOPDEV &> /dev/null
if [ $? == 0 ] ; then
    losetup -d /dev/$LOOPDEV
    mrxoutcode
fi

mrxtext "limpar tempario"
rm -rf $MNT
rm -rf $RAMMOUNTDIR
rm -rf $RAMIMAGE
rm -rf $RAMIMAGE.gz
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



mrxtext "calcular tamanho do temporario"
export tamanho=`du -sk $MNT | grep $MNT | tr -s [:blank:] "_" | cut -f1 -d "_"`

mrxtext "adiciona folga na tamanho"
export tamanho=$(($tamanho+$FOLGA_EM_KB))

mrxtext "cria imagem com $tamanho KB"
dd if=/dev/zero of=$RAMIMAGE bs=1k count=$tamanho
mrxoutcode

mrxtext "formatar imagem"
mkfs.minix $RAMIMAGE $tamanho
mrxoutcode

mrxtext "montar imagem no loop"
mkdir -p $RAMMOUNTDIR
mount $RAMIMAGE $RAMMOUNTDIR -t minix -o loop=/dev/$LOOPDEV
mrxoutcode

mrxtext "copiar de $MNT para $RAMMOUNTDIR"
cp -a $MNT/* $RAMMOUNTDIR

mrxtext "criar links ocultos"
ln -s /etc/profile 	$RAMMOUNTDIR/.bashrc
ln -s /etc/profile 	$RAMMOUNTDIR/.profile
mknod -m 600 $RAMMOUNTDIR/dev/console c 5 1 
mknod -m 666 $RAMMOUNTDIR/dev/null c 1 3    

mrxtext "desmontar imagem"
umount -d $RAMMOUNTDIR
mrxoutcode

mrxtext "compactar imagem"
gzip -v -9 $RAMIMAGE

if [ -f /boot/ramdisk.gz  ] ; then
    mrxtext "fazer backup da imagem atual"
    mv -v /boot/ramdisk.gz /boot/ramdisk-backup-`date +%F-%T`.gz
fi

mrxtext "instalar a nova imagem"
mv -v $RAMIMAGE.gz /boot/ramdisk.gz


mrxtext "ajuste no seu carregador de boot o tamanho do ramdisk para $tamanho"



#EOF

