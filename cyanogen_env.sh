export BUILD_TRUNK=$(pwd)

# envs for sunxi tools
export SUNXI_TOOLS_PATH=$(pwd)/loftq-build
export SUNXI_LINUX_PATH=$(pwd)/loftq-linux
export SUNXI_UBOOT_PATH=$(pwd)/loftq-uboot
export SUNXI_TOOLCHAIN_PATH=${SUNXI_TOOLS_PATH}/toolschain/gcc-linaro/bin
export SUNXI_TOOLS_BIN_PATH=$SUNXI_TOOLS_PATH/pack/pctools/linux:$SUNXI_TOOLS_PATH/pack/pctools/linux/android

# envs for android
export ANDROID_TRUNK=$(pwd)/cyanogenmod
export ANDROID_DEVICE=loftq
export ANDROID_DEVICE_TRUNK=${ANDROID_TRUNK}/device/mixtile/${ANDROID_DEVICE}


# commom env
export ANDROID_OUT=${ANDROID_TRUNK}/out
export ANDROID_DEVICE_OUT=${ANDROID_OUT}/target/product/${ANDROID_DEVICE}

export LINARO_GCC_PATH=$SUNXI_TOOLCHAIN_PATH
export PATH=$PATH:$LINARO_GCC_PATH:$SUNXI_TOOLS_BIN_PATH

export LANG=C
export LC_ALL=C

function check_toolchain()
{
	if [ -d $SUNXI_TOOLCHAIN_PATH ]; then
		echo "sunxi toolchain exists: $SUNXI_TOOLCHAIN_PATH"
	else
		tar -C $SUNXI_TOOLS_PATH/toolschain -xf $SUNXI_TOOLS_PATH/toolschain/gcc-linaro.tar.bz2
		echo "extract sunxi toolchain: $SUNXI_TOOLCHAIN_PATH"
	fi
}

function android_build_uboot()
{
	CURDIR=$PWD
	
	cd $SUNXI_UBOOT_PATH
	make distclean
	make sun6i_config
	make -j4
	cd $CURDIR
}

function android_build_kernel()
{
	CURDIR=$PWD

	cd $SUNXI_LINUX_PATH
	./build.sh -p sun6i_fiber

	cd -
}


function android_extract_bsp()
{
	LINUXOUT_DIR=$SUNXI_LINUX_PATH/output
	LINUXOUT_MODULE_DIR=$LINUXOUT_DIR/lib/modules/*/*
	CURDIR=$PWD

	cd $ANDROID_DEVICE_TRUNK

    #copy uboot to referring directory
    cp $SUNXI_UBOOT_PATH/u-boot-sun6i.bin $SUNXI_TOOLS_PATH/pack/chips/sun6i/bin/u-boot-sun6i.bin

	#extract kernel
	if [ -f kernel ]; then
		rm kernel
	fi

	cp $LINUXOUT_DIR/bImage kernel
	echo "$ANDROID_DEVICE_TRUNK/bImage copied!"
	
	#extract linux modules
	if [ -d modules ]; then
		rm -rf modules
	fi
	mkdir -p modules/modules
	cp -rf $LINUXOUT_MODULE_DIR modules/modules
	echo "$ANDROID_DEVICE_TRUNK/modules copied!"
	chmod 0755 modules/modules/*

	# create modules.mk
   	(cat << EOF) > ./modules/modules.mk
    # modules.mk generate by extract-files.sh , do not edit it !!!!
PRODUCT_COPY_FILES += \\
	\$(call find-copy-subdir-files,*,\$(LOCAL_PATH)/modules,system/vendor/modules)

EOF

	cd -
}

function android_pack()
{
	export CRANE_IMAGE_OUT=$ANDROID_DEVICE_OUT
	export PACKAGE=$SUNXI_TOOLS_PATH/pack

	cd $PACKAGE

	DEBUG="uart0"
	SIGMODE="none"

	if [ "$1" = "-d" -o "$2" = "-d" ]; then
		echo "--------debug version, have uart printf-------------"
		DEBUG="card0";
	else
		echo "--------release version, donnot have uart printf-------------"
	fi

	if [ "$1" = "-s" -o "$2" = "-s" ]; then
		echo "-------------------sig version-------------------"
		SIGMODE="sig";
	fi

	./pack -c sun6i -p android -b $ANDROID_DEVICE  -d ${DEBUG} -s ${SIGMODE}


	cd -
}

check_toolchain
