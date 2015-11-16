#!/bin/bash

function __text () {
printf "\33[1;33m$@\33[m\n"
}

__text "################################################################"
__text "# MURIX geniso maker                                           #"
__text "# Create by Murilo Pontes [murilopontes@gmail.com]             #"
__text "################################################################"

export DIR="/tmp/mrxcdram"

__text "DELETE OLD TEMP"
rm -rf $DIR
rm -rf $DIR.iso

__text "CREATE TEMP DIR"
mkdir -pv $DIR/

__text "COPY FILES"
cp -a README                    $DIR/
cp -a COPYING                   $DIR/
cp -a /vmlinuz                  $DIR/
cp -a /boot/memtest86+.bin      $DIR/memtest86.bin
cp -a /boot/ramdisk.gz          $DIR/
cp -a /usr/share/syslinux       $DIR/

__text "write menu.lst"
echo "
timeout 100
ui menu.c32
LABEL linux
  linux  vmlinuz
  append root=/dev/ram0 initrd=ramdisk.gz
LABEL memtest
  linux  memtest86.bin
" > $DIR/syslinux.cfg

__text "find system snapshot"
if [ -d /tmp/murix ] ; then
    DIR="$DIR /tmp/murix"
fi

__text "wait ISO image output=$DIR.iso"
# -l = allow 31chars in iso9660 
# -J = generate joliet
# -R = generate Rock 
# -o = output file
mkisofs -l -J -R  -b syslinux/isolinux.bin  -no-emul-boot -boot-load-size 4 -boot-info-table -o $DIR.iso $DIR
__text "isohybrid output=$DIR.iso"
isohybrid $DIR.iso
__text "The end"





