PXE Multiboot Server
====================

![PXE Boot Screenshot](http://jonschipp.com/pics/pxe-multiboot.jpg)

```
$ vagrant up
```

will provision a new PXE server with Linux images on your LAN via bridged network mode.
It automatically detects your IP address and configures dhcpd, tftpd, etc. for you and will begin serving out the image to DHCP clients.
Fire up the VM and then PXE boot a computer on your LAN.

Change bridge to your interface if it differs.
```
config.vm.network "public_network", bridge: 'en0: Ethernet Alias'
```

You can set args a valid iso url to deploy the image of your choice.
```
config.vm.provision "shell", path: "new_iso.sh", args: "--os Ubuntu --version 14.0.1 --ramdisk initrd.gz --kernel linux --url http://releases.ubuntu.com/14.04/ubuntu-14.04.1-server-amd64.iso"
```

Use the new_iso and new_pxe scripts to install new images.

The following command will add CentOS and DBAN as options to boot from, it will configure the entire thing beginning with downloading the iso, for PXE booting.
```
  ./new_iso --os CentOS --version 7.0 --url http://mirror.cs.uwp.edu/pub/centos/7.0.1406/isos/x86_64/CentOS-7.0-1406-x86_64-Minimal.iso"
  ./new_iso --os dban --version 2.2.8 --url http://sourceforge.net/projects/dban/files/dban/dban-2.2.8/dban-2.2.8_i586.iso --kernel dban.bzi"
```

The following command will backup and replace the menu system to install Kali Linux via PXE boot.
```
  ./new_pxe --url http://repo.kali.org/kali/dists/kali/main/installer-i386/current/images/netboot/netboot.tar.gz
```
