export LANG=C
export LC_ALL=C

OUTDIR=$(pwd)/out

mkdir -p $OUTDIR

# create boot cmd
mkimage -C none -A arm -T script -d boot_single.cmd $OUTDIR/boot.scr

