#!/bin/sh

/bin/busybox mount -t proc proc proc

ifconfig lo up 127.0.0.1
ifconfig eth0 up 10.0.2.15 netmask 255.255.255.0
route add default gw 10.0.2.2

mkdir -p /mnt/dest
mkdir -p /mnt/src

echo "----------------------------------------------"
nfspath=$(sed 's/.* nfspath=\([^ ]*\).*/\1/' /proc/cmdline)
copypath=/mnt/dest/$(sed 's/.* copypath=\([^ ]*\).*/\1/' /proc/cmdline)
filesystems=$(sed 's/.* filesystems=\([^ ]*\).*/\1/' /proc/cmdline)

echo "NFS path: $nfspath"
echo "Destination path: $copypath"
echo "Filesystems: $filesystems"
echo "----------------------------------------------"
echo

mount "$nfspath" /mnt/dest -o nolock || ( echo "ERROR: unable to mount NFS"; poweroff -f )

for fs in $(echo $filesystems | tr "," " "); do
  echo "Trying $fs"
  mount -t "$fs" -o ro /dev/hda /mnt/src
  if [ $? -eq 0 ]; then
    echo "SUCCESS: $fs"
    mkdir -p "$copypath/$fs"
    tar -pcC /mnt/src . | tar -pxv -C "$copypath/$fs"
    chown -R 206:280 "$copypath/$fs"
    # permissions changed by Tomas
    #chmod -R ug+rw "$copypath/$fs"
    find "$copypath/$fs" -type d -exec chmod a+r '{}' \;
    find "$copypath/$fs" -type f -exec chmod a+rx '{}' \;
    umount /mnt/src
    break 	# Tomas ???
  fi
done

umount /mnt/dest
sync
sync
poweroff -f
