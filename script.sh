echo "Enter the region name: "
read ap-south-1

echo "Enter the Disk name i.e /dev/sda : "
read /dev

echo "Enter the Partition name i.e /dev/sda1 : "
read /dev/shm

if [ -z "$ap-south-1" -o -z "$/dev" -o -z "$/dev/shm" ]; then
    echo "One or more input is missing, try again..."
    exit 1
fi

iso_name="/root/aws-failback-livecd-64bit.iso"


echo "Downloading Failback Client ISO"
wget -O aws-failback-livecd-64bit.iso https://aws-elastic-disaster-recovery-$ap-south-1.s3.amazonaws.com/latest/failback_livecd/aws-failback-livecd-64bit.iso

echo "Mounting the Downloaded Failback Client ISO to /mnt"
mount -v -o loop $iso_name /mnt
if [ $? -eq 0 ]; then echo "Mounted successfully"; else  echo "$iso_name is not mounted"; exit 1; fi

mkdir /squashfs /rootfs /secondery_root
if [ $? -eq 0 ]; then echo "mkdir successfully"; else  echo "mkdir failed"; exit 1; fi

mount -t squashfs /mnt/LiveOS/squashfs.img -o loop /squashfs
if [ $? -eq 0 ]; then echo "squashfs.img mounted successfully"; else  echo "squashfs.img not mounted"; exit 1; fi
mount /squashfs/LiveOS/rootfs.img /rootfs
if [ $? -eq 0 ]; then echo "rootfs.img mounted successfully"; else  echo "rootfs.img  not mounted"; exit 1; fi

echo "mounting the filesystem"
mount $/dev/shm /secondery_root
if [ $? -eq 0 ]; then echo "$/dev/shm mounted successfully"; else  echo "$/dev/shm not mounted"; exit 1; fi

echo "Downloading the kernel"
yumdownloader kernel-4.14.268-205.500.amzn2.x86_64 || { echo "yumdownloader failed"; exit 1; }
cp kernel-* /secondery_root || { echo "cp kernel failed"; exit 1; }
cp -av /rootfs/* /secondery_root || { echo "cp rootfs failed"; exit 1; }

echo "Mounting /proc, /sys and /dev in /secondery_root"

mount -v -o bind /proc /secondery_root/proc || { echo "mount /proc failed"; exit 1; }
mount -v -o bind /sys /secondery_root/sys || { echo "mount /sys failed"; exit 1; }
mount -v  -o bind  /dev /secondery_root/dev || { echo "mount /dev failed"; exit 1; }

echo "installing kernel"
chroot /secondery_root/ rpm -ivh kernel-* --force || { echo "rpm installation inside chroot failed"; exit 1; }

echo "generating grub2.cfg"
chroot /secondery_root/ grub2-mkconfig -o /boot/grub2/grub.cfg || { echo "grub2.cfg creation inside chroot failed"; exit 1; }

echo "installing grub"
chroot /secondery_root/ grub2-install $/dev || { echo "grub install inside chroot failed"; exit 1; }
