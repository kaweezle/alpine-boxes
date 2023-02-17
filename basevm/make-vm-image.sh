#!/bin/bash
set -e pipefail


ebegin() {
    echo -e -n '\e[s\e[1;32m* \e[0m'
    echo -e -n "$@"
    echo -e -n '...'
}

eend() {
    echo -e -n '\e[u\e[120C'
    echo -e -n '\e[7D'
    echo -e -n '\e[1;34m[ \e[0m'
    if [ $1 -eq 0 ]; then
         echo -e -n '\e[1;32mok\e[0m'
    else
         echo -e -n '\e[1;31m!!\e[0m'
    fi
    echo -e '\e[1;34m ]\e[0m'

    if [ $1 -ne 0 ]; then
        exit $1
    fi
}

vmname="alpinevm"
imgname="${vmname}.img"
vhdxname="${vmname}.vhdx"
qcowname="${vmname}.qcow2"

mntdir=$( mktemp -d )


ebegin "Creating image"
dd if=/dev/zero of=$imgname bs=1G count=1 >/dev/null 2>&1
eend $?

ebegin "Setting parition table"
echo "type=83,bootable" | sfdisk $imgname >/dev/null 2>&1
eend $?

ebegin "Creating loop device"
losetup -D && losetup -o 1048576 /dev/loop0 $imgname
eend $?

ebegin "Creating ext4 filesystem"
mkfs.ext4 -O ^64bit /dev/loop0 >/dev/null 2>&1
eend $?

ebegin "Building docker image"
docker buildx build -t basevm --load --quiet ./basevm >/dev/null 2>&1 && ID=$(docker create basevm)
eend $?

ebegin "Dumping image into partition"
mount /dev/loop0 $mntdir && \
    docker export $ID | tar x --numeric-owner -C $mntdir && \
    docker rm $ID >/dev/null 2>&1 && \
    dd if=$mntdir/usr/share/syslinux/mbr.bin of=$imgname bs=440 count=1 conv=notrunc >/dev/null 2>&1
eend $?

ebegin "Preparing chroot"
uuid=$(blkid -s UUID -o value /dev/loop0) && \
    mount -t proc none $mntdir/proc && \
    mount --bind /dev $mntdir/dev && \
    mount --bind /sys $mntdir/sys && \
    mount --make-private $mntdir/sys && \
    mount --make-private $mntdir/dev
eend $?

ebegin "Updating boot information"
echo "UUID=$uuid / ext4 noatime 0 1" > $mntdir/etc/fstab
sed -Ei \
    -e "s|^[# ]*(root)=.*|\1=UUID=$uuid|" \
    $mntdir/etc/update-extlinux.conf && \
    chroot $mntdir mkinitfs >/dev/null 2>&1 || /bin/true && \
    chroot $mntdir extlinux --install /boot >/dev/null 2>&1 && \
    chroot $mntdir update-extlinux --warn-only >/dev/null 2>&1
eend $?

ebegin "Cleaning chroot"
umount $mntdir/dev $mntdir/sys $mntdir/proc && umount $mntdir
eend $?

losetup -D
rm -rf $mntdir

ebegin "Converting image to VHDX"
qemu-img convert $imgname -O vhdx $vhdxname
eend $?

ebegin "Converting image to QCOW2"
qemu-img convert -c $imgname -O qcow2 $qcowname
eend $?
