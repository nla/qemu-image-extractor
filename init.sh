#!/bin/sh

/bin/busybox mount -t proc proc proc
/bin/busybox mount -t devtmpfs dev dev

ifconfig lo up 127.0.0.1
ifconfig eth0 up 10.0.2.15 netmask 255.255.255.0
route add default gw 10.0.2.2

mkdir -p /mnt/dest
mkdir -p /mnt/src

echo "----------------------------------------------"
filesystems=$(sed 's/.* filesystems=\([^ ]*\).*/\1/' /proc/cmdline)
copypath=/mnt/dest
echo "Filesystems: $filesystems"
echo "----------------------------------------------"
echo

if mount -t 9p -o trans=virtio,version=9p2000.L hostshare /mnt/dest; then
  echo Mounted 9p
else
  echo "ERROR: unable to mount 9p"
  poweroff -f
fi

for fs in $(echo $filesystems | tr "," " "); do
  echo "Trying $fs"
  mount -t "$fs" -o ro /dev/vda /mnt/src
  if [ $? -eq 0 ]; then
    if [ -e "$copypath/$fs" ]; then
      echo "ERROR: $copypath/$fs already exists, refusing to overwrite"
      poweroff -f
    fi
    cp -dR /mnt/src/ "$copypath/$fs"
    #tar -cC /mnt/src . | tar -xv -C "$copypath/$fs"
    #chown -R 206:280 "$copypath/$fs"
    chgrp -R 280 "$copypath/$fs"
    # permissions changed by Tomas
    #chmod -R ug+rw "$copypath/$fs"
    find "$copypath/$fs" -type d -exec chmod a+rx '{}' \;
    find "$copypath/$fs" -type f -exec chmod a+r '{}' \;
    umount /mnt/src
    echo "SUCCESS: $fs"
  fi
done

umount /mnt/dest
sync
sync
poweroff -f
