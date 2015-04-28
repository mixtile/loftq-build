export SUNXI_CHIP=sun8iw3p1
export BOARD_NAME=globot
export BUILD_TRUNK=$(pwd)
export BUILD_TRUNK_OUT=$BUILD_TRUNK/out

# envs for sunxi tools
export SUNXI_TOOLS_PATH=$(pwd)/sunxi-build
export SUNXI_LINUX_PATH=$(pwd)/globot-linux
export SUNXI_UBOOT_PATH=$(pwd)/globot-uboot
export SUNXI_UBOOT_NEXT_PATH=$(pwd)/uboot-next
export SUNXI_TOOLCHAIN_PATH=${SUNXI_TOOLS_PATH}/toolschain/gcc-linaro/bin
export SUNXI_TOOLS_ANDROID_PATH=$SUNXI_TOOLS_PATH/pack/pctools/linux/android
export SUNXI_TOOLS_LINUX_PATH=$SUNXI_TOOLS_PATH/pack/pctools/linux

export LINARO_GCC_PATH=$SUNXI_TOOLCHAIN_PATH
export PATH=$PATH:$LINARO_GCC_PATH:$SUNXI_TOOLS_ANDROID_PATH
export PATH=$PATH:$SUNXI_TOOLS_LINUX_PATH/mod_update:$SUNXI_TOOLS_LINUX_PATH/eDragonEx:$SUNXI_TOOLS_LINUX_PATH/fsbuild200
export LD_LIBRARY_PATH=${SUNXI_TOOLS_LINUX_PATH}/libs:$LD_LIBRARY_PATH
export CROSS_COMPILE=arm-linux-gnueabi-

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

function linux_build_uboot()
{
	cd $SUNXI_UBOOT_PATH
	make distclean
	make CROSS_COMPILE=arm-linux-gnueabi- ${SUNXI_CHIP}_config
    make CROSS_COMPILE=arm-linux-gnueabi- -j4
    cd -
}

function linux_build_uboot_next()
{	
	cd $SUNXI_UBOOT_NEXT_PATH
	make distclean
	make CROSS_COMPILE=arm-linux-gnueabi- mixtile_loftq_defconfig
	make CROSS_COMPILE=arm-linux-gnueabi- -j4
	cd -
}

function linux_build_kernel()
{
	cd $SUNXI_LINUX_PATH

    kernel_cfg=mixtile_globot_defconfig

    if [ -d output ]; then
        rm -rf output
        mkdir output
    fi

    if [ ! -e .config ]; then
        cp arch/arm/configs/${kernel_cfg} .config
    fi

    make clean
    # build kernel uImage    
    make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j16 uImage modules
   
    # build modules 
    make INSTALL_MOD_PATH=output ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j4 modules_install
    
    # build rootfs
    if [ -d skel ]; then
        rm -rf skel && mkdir skel
        gzip -dc rootfs.cpio.gz | (cd skel; fakeroot cpio -i)
    else
        mkdir skel
        gzip -dc rootfs.cpio.gz | (cd skel; fakeroot cpio -i)
    fi

    # copy kernel modules to referring directory of rootfs
    rm -rf ./output/lib/modules/3.4.39/build
    rm -rf ./output/lib/modules/3.4.39/source
    cp -r ./output/lib/modules ./skel/lib

    cd skel 
    find . | fakeroot cpio -o -Hnewc |gzip > ../output/rootfs.cpio.gz 
    cd ..

    cp -vf arch/arm/boot/Image output/bImage
    cp -vf arch/arm/boot/[zu]Image output/
    cp .config output/

    mkbootimg --kernel output/bImage \
        --ramdisk output/rootfs.cpio.gz \
        --board 'globot' \
        --base 0x40000000 \
        -o output/boot.img

	cd ..
}

function linux_pack()
{
    LINUX_IMAGE_NAME=globot_buildroot.img
	LINUX_PACK_OUT=$BUILD_TRUNK/out/linux
    LINUX_CHIP_CFG=$SUNXI_TOOLS_PATH/pack/chips/$SUNXI_CHIP
    LINUX_CFG=$SUNXI_TOOLS_PATH/pack/chips/$SUNXI_CHIP/configs/linux
	
	echo "Generating linux out directory!"
	mkdir -p $LINUX_PACK_OUT

    echo "copying misc configs!"
    cp -v $LINUX_CFG/default/* $LINUX_PACK_OUT/ 2>/dev/null
    cp -v $LINUX_CFG/$BOARD_NAME/*.fex $LINUX_PACK_OUT/ 2>/dev/null
    cp -v $LINUX_CFG/$BOARD_NAME/*.cfg $LINUX_PACK_OUT/ 2>/dev/null

    cp -rf $LINUX_CHIP_CFG/tools/split_xxxx.fex \
            $LINUX_CHIP_CFG/boot-resource/boot-resource \
            $LINUX_CHIP_CFG/boot-resource/boot-resource.ini \
        $LINUX_PACK_OUT/ 2>/dev/null

    cp -rf $LINUX_CHIP_CFG/tools/usbtool.fex \
            $LINUX_CHIP_CFG/tools/cardtool.fex \
            $LINUX_CHIP_CFG/tools/cardscript.fex \
        $LINUX_PACK_OUT/ 2>/dev/null

    cp -rf $LINUX_CHIP_CFG/tools/aultls32.fex \
            $LINUX_CHIP_CFG/tools/aultools.fex \
        $LINUX_PACK_OUT/ 2>/dev/null

    cp -v $LINUX_CHIP_CFG/bin/boot0_nand_$SUNXI_CHIP.bin $LINUX_PACK_OUT/boot0_nand.fex 2>/dev/null
    cp -v $LINUX_CHIP_CFG/bin/boot0_sdcard_$SUNXI_CHIP.bin $LINUX_PACK_OUT/boot0_sdcard.fex 2>/dev/null
    cp -v $LINUX_CHIP_CFG/bin/fes1_$SUNXI_CHIP.bin $LINUX_PACK_OUT/fes1.fex 2>/dev/null
	
	echo "Copying uboot!"
	cp $SUNXI_UBOOT_PATH/u-boot.bin $LINUX_PACK_OUT/u-boot.fex 2>/dev/null
	
    echo "Copying linux kernel and modules!"
	cp $SUNXI_LINUX_PATH/output/*Image $LINUX_PACK_OUT 2>/dev/null
	cp $SUNXI_LINUX_PATH/output/boot.img $LINUX_PACK_OUT 2>/dev/null
	cp -r $SUNXI_LINUX_PATH/output/lib $LINUX_PACK_OUT 2>/dev/null

    echo ""

    cd $LINUX_PACK_OUT

    sed -i 's/\\boot-resource/\/boot-resource/g' boot-resource.ini
    sed -i 's/\\\\/\//g' image.cfg
    sed -i 's/imagename/;imagename/g' image.cfg
    echo "imagename = $LINUX_IMAGE_NAME" >> image.cfg
    echo "" >> image.cfg

    busybox unix2dos sys_config.fex
    busybox unix2dos sys_partition.fex
    script sys_config.fex
    script sys_partition.fex

    cp sys_config.bin  config.fex

    update_boot0 boot0_nand.fex   sys_config.bin NAND
    update_boot0 boot0_sdcard.fex sys_config.bin SDMMC_CARD

    update_uboot u-boot.fex  sys_config.bin

    update_fes1  fes1.fex  sys_config.bin

    update_mbr sys_partition.bin  4

    fsbuild boot-resource.ini split_xxxx.fex
    mv boot-resource.fex bootloader.fex
    # get env.fex
    u_boot_env_gen env.cfg env.fex

    mv boot.img boot.fex

    mv rootfs.ext4 rootfs.fex

    signature sunxi_mbr.fex dlinfo.fex
        
    dragon image.cfg sys_partition.fex

    echo '---------image is at-------------'
    echo -e '\033[0;31;1m'
    echo $LINUX_PACK_OUT/$LINUX_IMAGE_NAME
    echo -e '\033[0m'
    cd ../../
}

check_toolchain
