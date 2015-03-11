bootdelay=3
console=ttyS0,115200
mmc_root=/dev/mmcblk1p1
init=/sbin/init
loglevel=8

setenv bootargs noinitrd console=${console} console=tty0 init=${init} loglevel=${loglevel} partitions={partitions} root=${mmc_root} rootwait rw rootfstype=ext4 panic=10 consoleblank=0  hdmi.audio=EDID:0 disp.screen0_output_mode=EDID:1280x720p60 ${extra}

ext4load mmc 0 0x43000000 boot/script.bin
ext4load mmc 0 0x48000000 boot/uImage
bootm 0x48000000
