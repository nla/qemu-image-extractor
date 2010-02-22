#!/bin/bash
QHOME=$(cd -P -- "$(dirname -- "$0")/.." && pwd -P)
LD_LIBRARY_PATH="$QHOME"

DISK_IMAGE="$1"
NFS_PATH="$2"
COPY_PATH="$3"
FILESYSTEMS="$4"

if [ -z "$FILESYSTEMS" ]; then
  echo "Usage: $0 disk.img ip.address:/nfs/path destination_path filesystems"
  echo "Example: $0 /doss/doss-devel/working/digipres/test/images/nla.dp-n113301/nla.dp-n113301.img 192.102.239.241:/doss-devel working/digipres/test/images/nla.dp-n113301/filesystem xfs,udf,iso9660,ext3"
  exit 1
fi

exec "$QHOME"/bin/qemu-system-x86_64 \
  -kernel "$QHOME/lib/linux" \
  -initrd "$QHOME/lib/initramfs" \
  -serial stdio \
  -hda "$DISK_IMAGE" \
  -append "console=ttyS0 quiet nfspath=$NFS_PATH copypath=$COPY_PATH filesystems=$FILESYSTEMS"
