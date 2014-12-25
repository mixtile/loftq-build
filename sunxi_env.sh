export BUILD_TRUNK=$(pwd)
export BUILD_TRUNK_OUT=$BUILD_TRUNK/out

# envs for sunxi tools
export SUNXI_TOOLS_PATH=$(pwd)/LoftQ.tools
export SUNXI_LINUX_PATH=$(pwd)/linux-3.3
export SUNXI_UBOOT_PATH=$(pwd)/u-boot-2011.09
export SUNXI_TOOLCHAIN_PATH=${SUNXI_TOOLS_PATH}/toolschain/gcc-linaro/bin/

# envs for android
export ANDROID_TRUNK=$(pwd)/android
export ANDROID_DEVICE=loftq
export ANDROID_DEVICE_TRUNK=${ANDROID_TRUNK}/device/mixtile/${ANDROID_DEVICE}

# envs for ubuntu touch 
# only used if we have android base sdk released by ubuntu touch team
# Note: now we can build this image but can't burn it to disk with PhoenixTool
export UBUNTU_OUTPUT=$BUILD_TRUNK_OUT/ubuntu
export UBUNTU_TARBALL=$UBUNTU_OUTPUT/vivid-preinstalled-touch-armhf.tar.gz

# commom env
export ANDROID_OUT=${ANDROID_TRUNK}/out
export ANDROID_DEVICE_OUT=${ANDROID_OUT}/target/product/${ANDROID_DEVICE}

export LINARO_GCC_PATH=$SUNXI_TOOLCHAIN_PATH
export PATH=$PATH:$LINARO_GCC_PATH

export LANG=C
export LC_ALL=C

function check_toolchain()
{
	if [ -d $SUNXI_TOOLCHAIN_PATH ]; then
		echo "sunxi toolchain exists: $SUNXI_TOOLCHAIN_PATH";
	else
		tar -C $SUNXI_TOOLS_PATH/toolschain -xf $SUNXI_TOOLS_PATH/toolschain/gcc-linaro.tar.bz2
		echo "extract sunxi toolchain: $SUNXI_TOOLCHAIN_PATH";
		echo ""
	fi
}

function linux_build_uboot()
{
    CURDIR=$PWD

    cd $SUNXI_UBOOT_PATH
    make distclean
    make sun6i_config
    make -j4
    cd $CURDIR
}

function linux_build_kernel()
{
	CURDIR=$PWD

	cd $SUNXI_LINUX_PATH
	./build.sh -p sun6i

	cd $CURDIR
}

function linux_pack()
{
    LINUX_PACK_OUT=$BUILD_TRUNK/out/linux

    echo "Generating linux out directory!"
    mkdir -p $LINUX_PACK_OUT

    echo "Copiing uboot!"
    cp $SUNXI_UBOOT_PATH/u-boot.bin $LINUX_PACK_OUT 
    cp $SUNXI_UBOOT_PATH/u-boot-sun6i.bin $SUNXI_TOOLS_PATH/pack/chips/sun6i/bin/
    echo "Copying linux kernel and modules!"
    cp $SUNXI_LINUX_PATH/output/*Image $LINUX_PACK_OUT
    cp $SUNXI_LINUX_PATH/output/boot.img $LINUX_PACK_OUT
    cp -r $SUNXI_LINUX_PATH/output/lib $LINUX_PACK_OUT

    echo "Packing final image!"
    $SUNXI_TOOLS_PATH/scripts/build_pack.sh
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

	cd $CURDIR
}


function android_extract_bsp()
{
	LINUXOUT_DIR=$SUNXI_LINUX_PATH/output
	LINUXOUT_MODULE_DIR=$LINUXOUT_DIR/lib/modules/*/*
	CURDIR=$PWD

	cd $ANDROID_DEVICE_TRUNK

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

	./pack -c sun6i -p android -b loftq  -d ${DEBUG} -s ${SIGMODE}


	cd -
}

function android_to_ubuntu()
{
	ANDROID_IMG=$ANDROID_DEVICE_OUT/system.img
	TOUCH_TARBALL=$UBUNTU_TARBALL

	sudo $SUNXI_TOOLS_PATH/utouch_mkimg.sh $TOUCH_TARBALL $ANDROID_IMG
}

check_toolchain
