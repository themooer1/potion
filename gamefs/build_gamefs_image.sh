#! /bin/sh

mke2fs \
  -L '' \
  -N 0 \
  -O ^64bit \
  -d "/gamefs-staging" \
  -m 5 \
  -r 1 \
  -t ext4 \
  "/gamefs.ext4" \
  400M \
;