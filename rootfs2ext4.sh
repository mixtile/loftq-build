#!/bin/sh
# genext2fs wrapper calculating needed blocks/inodes values if not specified

export LC_ALL=C

CALC_BLOCKS=0
CALC_INODES=0

while getopts x:d:D:b:t:i:N:m:g:e:zfqUPhVv f
do
    case $f in
    d) ROOTFS_DIR=$OPTARG ;;
    t) TARGET_EXT4=$OPTARG ;;
    esac
done

# calculate needed inodes
CALC_INODES=$(find $ROOTFS_DIR | wc -l)
CALC_INODES=$(expr $CALC_INODES + 400)

echo "inodes : $CALC_INODES"

# calculate needed blocks
# size ~= superblock, block+inode bitmaps, inodes (8 per block), blocks
# we scale inodes / blocks with 10% to compensate for bitmaps size + slack
CALC_BLOCKS=$(du -s -c -k $ROOTFS_DIR | grep total | sed -e "s/total//")
CALC_BLOCKS=$(expr 500 + \( $CALC_BLOCKS + $CALC_INODES / 8 \) \* 13 / 10)

echo "blocks: $CALC_BLOCKS"

exec genext2fs -N $CALC_INODES -b $CALC_BLOCKS -d $ROOTFS_DIR $TARGET_EXT4

tune2fs -j -O extents,uninit_bg,dir_index,has_journal $TARGET_EXT4
fsck.ext4 -y $TARGET_EXT4

echo $TARGET_EXT4
