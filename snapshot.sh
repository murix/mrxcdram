#!/bin/bash

source version.sh

function __text() {
echo -e "\33[01;33m$@\33[m"
}

__text "################################################################"
__text "# MURIX snapshot maker $VERSION"
__text "# Create by Murilo Pontes [murilopontes@users.sourceforge.net] #"
__text "################################################################"

rm -vrf /tmp/murix
mkdir -p /tmp/murix
tar cfvz /tmp/murix/snapshot.tar.gz /vmlinuz* /System.* /bin /boot /etc /lib /mnt /opt /sbin /usr /var
