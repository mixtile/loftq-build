#!/bin/sh

export LC_ALL=C
export LANG=C

set -e

UBUNTU_SIZE=2G
TARPATH=$1
SYSIMG=$2
OUT_DIR=$(dirname $SYSIMG)/tmp

check_prereq()
{
	if [ ! $(which make_ext4fs) ] || [ ! -x $(which simg2img) ] || \
		[ ! -x $(which adb) ]; then
		echo "please install the android-tools-fsutils and android-tools-adb packages" && exit 1
	fi
}

prepare_android_img()
{
	echo -n "adding android system image to installation ... "

	ANDROID_OUT=$OUT_DIR/

	ANDROID_ROOT=$ANDROID_OUT/android.mnt

	cp $SYSIMG $ANDROID_OUT/android.img

	simg2img $ANDROID_OUT/android.img $ANDROID_OUT/android.img.raw
	[ -e $ANDROID_ROOT ] && rm -r $ANDROID_ROOT
	mkdir $ANDROID_ROOT
	mount -t ext4 -o loop $ANDROID_OUT/android.img.raw $ANDROID_ROOT
	make_ext4fs -l 180M $ANDROID_OUT/android.img.new $ANDROID_ROOT 

	umount $ANDROID_ROOT
	#rm -rf $ANDROID_ROOT
	#rm $ANDROID_OUT/android.img
	#rm $ANDROID_OUT/android.img.raw
	sync
	echo "[done]"
}

build_ubuntu_rootfs()
{
	# prepare ubuntu target image
	echo -n "preparing ubuntu target image ... "
	UBUNTU_OUT=$OUT_DIR
	UBUNTU_ROOT=$UBUNTU_OUT/ubuntu.mnt

	mkdir -p $UBUNTU_OUT

	dd if=/dev/zero of=$UBUNTU_OUT/ubuntu.img bs=$UBUNTU_SIZE count=1
	mkfs.ext2 -F $UBUNTU_OUT/ubuntu.img 
	[ -e $UBUNTU_ROOT ] && rm -r $UBUNTU_ROOT
	mkdir -p $UBUNTU_ROOT

	mount -o loop $UBUNTU_OUT/ubuntu.img $UBUNTU_ROOT >/dev/null 2>&1
	echo "[done]"

	
	# unpacking rootfs tarball
	echo -n "unpacking rootfs tarball to ubuntu image ... "

	tar -C $UBUNTU_ROOT -xzf $TARPATH

	sync

	cd $UBUNTU_ROOT

	mkdir -p android/firmware
	mkdir -p android/persist
	mkdir -p userdata

	#[ -e SWAP.swap ] && mv SWAP.swap SWAP.img

	for link in cache data factory firmware persist system 
		do
			ln -s /android/$link $link
		done
	
	cd -

	cd $UBUNTU_ROOT/lib && ln -s /system/lib/modules modules

	cd -

	cd $UBUNTU_ROOT && ln -s /android/system/vendor vendor
	
	cd -

	[ -e $UBUNTU_ROOT/etc/mtab ] && rm $UBUNTU_ROOT/etc/mtab

	cd $UBUNTU_ROOT/etc && ln -s /proc/mounts mtab

	cd -

	# move android image to lxc container directory

	ANDROID_DIR=$UBUNTU_ROOT/var/lib/lxc/android
	cp $ANDROID_OUT/android.img.new $ANDROID_DIR/system.img 

	echo "[done]"

	# enable mir display
	echo -n "enabling Mir ... "
	touch $UBUNTU_ROOT/home/phablet/.display-mir
	echo "[done]"
	sync
	# clean ubuntu mounting dir
	umount $UBUNTU_ROOT
	rm -rf $UBUNTU_ROOT
	mv  $ANDROID_OUT/ubuntu.img $SYSIMG
	chmod 0665 $SYSIMG
	sync
}

check_prereq

prepare_android_img

build_ubuntu_rootfs





