#!/bin/bash
# Run once on first boot
COUNT=0
SUCCESS=0
HOME=/home/vagrant
export LFS=/mnt/lfs

touch /tmp/ran.provision.$(date +"%d-%m-%Y").shell

# For variable re-use
echo "export LFS=/mnt/lfs" > /etc/profile.d/lfs.sh
chmod 660 /etc/profile.d/lfs.sh

apt-get update
sudo apt-get install -y build-essential bison gawk vim util-linux expect

# Download packages

mkdir sources
cd sources

for package in http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.xz http://ftp.gnu.org/gnu/automake/automake-1.14.1.tar.xz http://ftp.gnu.org/gnu/bash/bash-4.2.tar.gz http://alpha.gnu.org/gnu/bc/bc-1.06.95.tar.bz2 http://ftp.gnu.org/gnu/binutils/binutils-2.24.tar.bz2 http://ftp.gnu.org/gnu/bison/bison-3.0.2.tar.xz http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz http://sourceforge.net/projects/check/files/check/0.9.12/check-0.9.12.tar.gz http://ftp.gnu.org/gnu/coreutils/coreutils-8.22.tar.xz http://ftp.gnu.org/gnu/dejagnu/dejagnu-1.5.1.tar.gz http://ftp.gnu.org/gnu/diffutils/diffutils-3.3.tar.xz http://prdownloads.sourceforge.net/e2fsprogs/e2fsprogs-1.42.9.tar.gz http://prdownloads.sourceforge.net/expect/expect5.45.tar.gz ftp://ftp.astron.com/pub/file/file-5.17.tar.gz http://ftp.gnu.org/gnu/findutils/findutils-4.4.2.tar.gz http://prdownloads.sourceforge.net/flex/flex-2.5.38.tar.bz2 http://ftp.gnu.org/gnu/gawk/gawk-4.1.0.tar.xz http://ftp.gnu.org/gnu/gcc/gcc-4.8.2/gcc-4.8.2.tar.bz2 http://ftp.gnu.org/gnu/gdbm/gdbm-1.11.tar.gz http://ftp.gnu.org/gnu/gettext/gettext-0.18.3.2.tar.gz http://ftp.gnu.org/gnu/glibc/glibc-2.19.tar.xz http://ftp.gnu.org/gnu/gmp/gmp-5.1.3.tar.xz http://ftp.gnu.org/gnu/grep/grep-2.16.tar.xz http://ftp.gnu.org/gnu/groff/groff-1.22.2.tar.gz http://ftp.gnu.org/gnu/grub/grub-2.00.tar.xz http://ftp.gnu.org/gnu/gzip/gzip-1.6.tar.xz http://anduin.linuxfromscratch.org/sources/LFS/lfs-packages/conglomeration//iana-etc/iana-etc-2.30.tar.bz2 http://ftp.gnu.org/gnu/inetutils/inetutils-1.9.2.tar.gz http://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-3.12.0.tar.xz http://ftp.altlinux.org/pub/people/legion/kbd/kbd-2.0.1.tar.gz http://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-16.tar.xz http://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-16.tar.xz http://www.greenwoodsoftware.com/less/less-458.tar.gz http://www.linuxfromscratch.org/lfs/downloads/7.5/lfs-bootscripts-20130821.tar.bz2 http://download.savannah.gnu.org/releases/libpipeline/libpipeline-1.2.6.tar.gz http://ftp.gnu.org/gnu/libtool/libtool-2.4.2.tar.gz http://www.kernel.org/pub/linux/kernel/v3.x/linux-3.13.3.tar.xz http://ftp.gnu.org/gnu/m4/m4-1.4.17.tar.xz http://ftp.gnu.org/gnu/make/make-4.0.tar.bz2 http://download.savannah.gnu.org/releases/man-db/man-db-2.6.6.tar.xz http://www.kernel.org/pub/linux/docs/man-pages/man-pages-3.59.tar.xz http://www.multiprecision.org/mpc/download/mpc-1.0.2.tar.gz http://www.mpfr.org/mpfr-3.1.2/mpfr-3.1.2.tar.xz http://ftp.gnu.org/gnu/ncurses/ncurses-5.9.tar.gz http://ftp.gnu.org/gnu/patch/patch-2.7.1.tar.xz http://www.cpan.org/src/5.0/perl-5.18.2.tar.bz2 http://pkgconfig.freedesktop.org/releases/pkg-config-0.28.tar.gz http://sourceforge.net/projects/procps-ng/files/Production/procps-ng-3.3.9.tar.xz http://prdownloads.sourceforge.net/psmisc/psmisc-22.20.tar.gz http://ftp.gnu.org/gnu/readline/readline-6.2.tar.gz http://ftp.gnu.org/gnu/sed/sed-4.2.2.tar.bz2 http://cdn.debian.net/debian/pool/main/s/shadow/shadow_4.1.5.1.orig.tar.gz http://www.infodrom.org/projects/sysklogd/download/sysklogd-1.5.tar.gz http://download.savannah.gnu.org/releases/sysvinit/sysvinit-2.88dsf.tar.bz2 http://ftp.gnu.org/gnu/tar/tar-1.27.1.tar.xz http://prdownloads.sourceforge.net/tcl/tcl8.6.1-src.tar.gz http://www.iana.org/time-zones/repository/releases/tzdata2013i.tar.gz http://ftp.gnu.org/gnu/texinfo/texinfo-5.2.tar.xz http://www.freedesktop.org/software/systemd/systemd-208.tar.xz http://anduin.linuxfromscratch.org/sources/other/udev-lfs-208-3.tar.bz2 http://www.kernel.org/pub/linux/utils/util-linux/v2.24/util-linux-2.24.1.tar.xz ftp://ftp.vim.org/pub/vim/unix/vim-7.4.tar.bz2 http://tukaani.org/xz/xz-5.0.5.tar.xz http://www.zlib.net/zlib-1.2.8.tar.xz http://www.linuxfromscratch.org/patches/lfs/7.5/bash-4.2-fixes-12.patch http://www.linuxfromscratch.org/patches/lfs/7.5/bzip2-1.0.6-install_docs-1.patch http://www.linuxfromscratch.org/patches/lfs/7.5/coreutils-8.22-i18n-4.patch http://www.linuxfromscratch.org/patches/lfs/7.5/glibc-2.19-fhs-1.patch http://www.linuxfromscratch.org/patches/lfs/7.5/kbd-2.0.1-backspace-1.patch http://www.linuxfromscratch.org/patches/lfs/7.5/perl-5.18.2-libc-1.patch http://www.linuxfromscratch.org/patches/lfs/7.5/readline-6.2-fixes-2.patch http://www.linuxfromscratch.org/patches/lfs/7.5/sysvinit-2.88dsf-consolidated-1.patch http://www.linuxfromscratch.org/patches/lfs/7.5/tar-1.27.1-manpage-1.patch
do
	COUNT=$((COUNT+1))
	wget $package 2>/dev/null
	if [ $? -ne 0 ]; then
		echo "$COUNT - Download for $package failed!"
	else
		echo "$COUNT - Success! for $package"
		SUCCESS=$((SUCCESS+1))
	fi
done

echo "**** Downloaded $SUCCESS packages of $COUNT ****"
sudo xz -d *.xz
sudo gzip -d *.gz
sudo bzip2 -d *.bz*

for tarball in *.tar
do
	sudo tar xf $tarball
done

cd ~/

/usr/bin/expect <<EOF
spawn sudo fdisk /dev/sdb
expect "Command \(m for help\):"
send "n\n"
expect "Select \(default p\):"
send "p\n"
expect "Partition number"
send "1\n"
expect "First sector"
send "\n"
expect "Last sector"
send "+9G\n"

expect "Command \(m for help\):"
send "n\n"
expect "Select \(default p\):"
send "p\n"
expect "Partition number"
send "2\n"
expect "First sector"
send "\n"
expect "Last sector"
send "\n"

expect "Command \(m for help\):"
send "t\n"
expect "Partition number"
send "2\n"
expect "Hex code"
send "82\n"

expect "Command \(m for help\):"
send "t\n"
expect "Partition number"
send "1\n"
expect "Hex code"
send "83\n"

expect "Command \(m for help\):"
send "w\n"
expect "Syncing disks"
EOF

sudo mkfs -t ext4 /dev/sdb1
sudo mkswap /dev/sdb2
sudo chmod 0660 /dev/sdb2
sudo swapon -v /dev/sdb2
sudo mkdir -pv $LFS
sudo mount -v -t ext4 /dev/sdb1 $LFS

for dir in home usr var
do
	sudo mkdir $LFS/$dir
done

if [ -d $LFS ]
then
	sudo mv $HOME/sources $LFS
fi

#http://ftp.gnu.org/gnu/bison/bison-3.0.2.tar.xz
#http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz
#http://sourceforge.net/projects/check/files/check/0.9.12/check-0.9.12.tar.gz
#http://ftp.gnu.org/gnu/coreutils/coreutils-8.22.tar.xz
#http://ftp.gnu.org/gnu/dejagnu/dejagnu-1.5.1.tar.gz
#http://ftp.gnu.org/gnu/diffutils/diffutils-3.3.tar.xz
#
## Pg 17
#http://prdownloads.sourceforge.net/e2fsprogs/e2fsprogs-1.42.9.tar.gz
#http://prdownloads.sourceforge.net/expect/expect5.45.tar.gz
#ftp://ftp.astron.com/pub/file/file-5.17.tar.gz
#http://ftp.gnu.org/gnu/findutils/findutils-4.4.2.tar.gz
#http://prdownloads.sourceforge.net/flex/flex-2.5.38.tar.bz2
#http://ftp.gnu.org/gnu/gawk/gawk-4.1.0.tar.xz
#http://ftp.gnu.org/gnu/gcc/gcc-4.8.2/gcc-4.8.2.tar.bz2
#http://ftp.gnu.org/gnu/gdbm/gdbm-1.11.tar.gz
#http://ftp.gnu.org/gnu/gettext/gettext-0.18.3.2.tar.gz
#
## Pg 18
#http://ftp.gnu.org/gnu/glibc/glibc-2.19.tar.xz
#http://ftp.gnu.org/gnu/gmp/gmp-5.1.3.tar.xz
#http://ftp.gnu.org/gnu/grep/grep-2.16.tar.xz
#http://ftp.gnu.org/gnu/groff/groff-1.22.2.tar.gz
#http://ftp.gnu.org/gnu/grub/grub-2.00.tar.xz
#http://ftp.gnu.org/gnu/gzip/gzip-1.6.tar.xz
#http://anduin.linuxfromscratch.org/sources/LFS/lfs-packages/conglomeration//iana-etc/iana-etc-2.30.tar.bz2
#http://ftp.gnu.org/gnu/inetutils/inetutils-1.9.2.tar.gz
#http://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-3.12.0.tar.xz
#http://ftp.altlinux.org/pub/people/legion/kbd/kbd-2.0.1.tar.gz
#http://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-16.tar.xz
#
## Pg 19
#http://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-16.tar.xz
#http://www.greenwoodsoftware.com/less/less-458.tar.gz
#http://www.linuxfromscratch.org/lfs/downloads/7.5/lfs-bootscripts-20130821.tar.bz2
#http://download.savannah.gnu.org/releases/libpipeline/libpipeline-1.2.6.tar.gz
#http://ftp.gnu.org/gnu/libtool/libtool-2.4.2.tar.gz
#http://www.kernel.org/pub/linux/kernel/v3.x/linux-3.13.3.tar.xz
#http://ftp.gnu.org/gnu/m4/m4-1.4.17.tar.xz
#http://ftp.gnu.org/gnu/make/make-4.0.tar.bz2
#http://download.savannah.gnu.org/releases/man-db/man-db-2.6.6.tar.xz
#
## Pg 20
#http://www.kernel.org/pub/linux/docs/man-pages/man-pages-3.59.tar.xz
#http://www.multiprecision.org/mpc/download/mpc-1.0.2.tar.gz
#http://www.mpfr.org/mpfr-3.1.2/mpfr-3.1.2.tar.xz
#http://ftp.gnu.org/gnu/ncurses/ncurses-5.9.tar.gz
#http://ftp.gnu.org/gnu/patch/patch-2.7.1.tar.xz
#http://www.cpan.org/src/5.0/perl-5.18.2.tar.bz2
#http://pkgconfig.freedesktop.org/releases/pkg-config-0.28.tar.gz
#http://sourceforge.net/projects/procps-ng/files/Production/procps-ng-3.3.9.tar.xz
#http://prdownloads.sourceforge.net/psmisc/psmisc-22.20.tar.gz
#http://ftp.gnu.org/gnu/readline/readline-6.2.tar.gz
#
## Pg 21
#http://ftp.gnu.org/gnu/sed/sed-4.2.2.tar.bz2
#http://cdn.debian.net/debian/pool/main/s/shadow/shadow_4.1.5.1.orig.tar.gz
#http://www.infodrom.org/projects/sysklogd/download/sysklogd-1.5.tar.gz
#http://download.savannah.gnu.org/releases/sysvinit/sysvinit-2.88dsf.tar.bz2
#http://ftp.gnu.org/gnu/tar/tar-1.27.1.tar.xz
#http://prdownloads.sourceforge.net/tcl/tcl8.6.1-src.tar.gz
#http://www.iana.org/time-zones/repository/releases/tzdata2013i.tar.gz
#http://ftp.gnu.org/gnu/texinfo/texinfo-5.2.tar.xz
#http://www.freedesktop.org/software/systemd/systemd-208.tar.xz
#http://anduin.linuxfromscratch.org/sources/other/udev-lfs-208-3.tar.bz2
#http://www.kernel.org/pub/linux/utils/util-linux/v2.24/util-linux-2.24.1.tar.xz
#
## 22
#ftp://ftp.vim.org/pub/vim/unix/vim-7.4.tar.bz2
#http://tukaani.org/xz/xz-5.0.5.tar.xz
#http://www.zlib.net/zlib-1.2.8.tar.xz
#
## Patches 22+23
#http://www.linuxfromscratch.org/patches/lfs/7.5/bash-4.2-fixes-12.patch
#http://www.linuxfromscratch.org/patches/lfs/7.5/bzip2-1.0.6-install_docs-1.patch
#http://www.linuxfromscratch.org/patches/lfs/7.5/coreutils-8.22-i18n-4.patch
#http://www.linuxfromscratch.org/patches/lfs/7.5/glibc-2.19-fhs-1.patch
#http://www.linuxfromscratch.org/patches/lfs/7.5/kbd-2.0.1-backspace-1.patch
#http://www.linuxfromscratch.org/patches/lfs/7.5/perl-5.18.2-libc-1.patch
#http://www.linuxfromscratch.org/patches/lfs/7.5/readline-6.2-fixes-2.patch
#http://www.linuxfromscratch.org/patches/lfs/7.5/sysvinit-2.88dsf-consolidated-1.patch
#http://www.linuxfromscratch.org/patches/lfs/7.5/tar-1.27.1-manpage-1.patch
