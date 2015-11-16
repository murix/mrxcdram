#!/bin/sh


source version.sh

function __text () {
printf "\33[1;33m$@\33[m\n"
}

__text "################################################################"
__text "# MURIX geniso maker $VERSION"
__text "# Create by Murilo Pontes [murilopontes@users.sourceforge.net] #"
__text "################################################################"

export data=`date +%F-%T`
export DIR="/tmp/mrxcdram"
export ISO="/tmp/murix-$data.iso"
export GRUB="-b boot/grub/iso9660_stage1_5 -c boot/boot.cat -no-emul-boot -boot-load-size 32 -boot-info-table"

__text "DELETE OLD TEMP"
rm -rf $DIR
rm -rf $ISO

__text "CREATE DIR"
mkdir -pv $DIR/boot/grub/

__text "COPY FILES"
cp -v README                    $DIR/
cp -v COPYING                   $DIR/
cp -v /vmlinuz                  $DIR/
cp -v /opt/memtest/precomp.bin 	$DIR/memtest86.bin
cp -v /boot/ramdisk.gz          $DIR/
cp -v /usr/share/grub/i386-pc/* $DIR/boot/grub/


__text "find ramdisk size"
cp -vf /boot/ramdisk.gz /tmp/test.gz
gunzip -f /tmp/test.gz
export tamanho=`du -sk /tmp/test | grep /tmp/test | tr -s [:blank:] "_" | cut -f1 -d "_"`

__text "write menu.lst"
echo "
default 0

timeout 30
color green/black light-green/black

title linux-ramdisk
kernel /vmlinuz root=/dev/ram0 vga=extended acpi=force ramdisk_size=$tamanho
initrd /ramdisk.gz

title memtest86
kernel /memtest86.bin 

" > $DIR/boot/grub/menu.lst


__text "find system snapshot"
if [ -d /tmp/murix ] ; then
    DIR="$DIR /tmp/murix"
fi

__text "wait ISO image output=$DIR.iso (ramdisk_size=$tamanho)"
# -l = allow 31chars in iso9660 
# -J = generate joliet
# -R = generate Rock 
# -pad = 
# -o = output file

mkisofs -l -J -R -pad $GRUB -o $ISO $DIR


#EOF

