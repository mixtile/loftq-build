LoftQ.tools
===========

tools for Loftq, including toolchains, build scripts, sunxi packing tools, etc

# Usage

## Download

```shell
git clone https://github.com/mixtile/LoftQ.tools.git
```

## Prepare

```shell
source LoftQ.tools/sunxi_env.sh
```

## Build

we have to download uboot, linux, buildroot or android code before we continue commands as below:

* build uboot for linux

```shell
linux_build_uboot
```

* build kernel for linux
```shell
linux_build_kernel
```

* pack final image for linux

**Note: before we pack for linux, we have to build rootfs.ext4 of buildroot or other linux rootfs.and put the rootfs in $BUILD_TRUNK/out/linux directory.**

```shell
linux_pack
```


