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
  -drive file="$DISK_IMAGE",readonly=on,if=virtio \
  -fsdev local,security_model=passthrough,id=fsdev0,path=$COPY_PATH -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare \
  -append "noapic console=ttyS0 quiet filesystems=$FILESYSTEMS"
