bootdelay=3
console=ttyS0,115200
mmc_root=/dev/mmcblk0p1
init=/sbin/init
loglevel=8
vmalloc=384M

setenv bootargs noinitrd console=${console} console=tty0 init=${init} loglevel=${loglevel} vmalloc=${vmalloc} partitions=${partitions} root=${mmc_root} rootwait rw rootfstype=ext4 panic=10 consoleblank=0 ${extra}

ext4load mmc 0 0x43000000 boot/script.bin
ext4load mmc 0 0x48000000 boot/uImage
bootm 0x48000000

