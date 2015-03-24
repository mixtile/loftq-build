INSTALL_MOD_PATH=output

mkdir -p $INSTALL_MOD_PATH/boot 

make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi-
make INSTALL_MOD_PATH=output ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- modules_install
cp arch/arm/boot/zImage $INSTALL_MOD_PATH/boot
cp arch/arm/boot/dts/sun6i-a31-mixtile-loftq.dtb $INSTALL_MOD_PATH/boot
