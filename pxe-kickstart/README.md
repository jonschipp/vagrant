PXE Kickstart
=============

```
$ vagrant up
```

will provision a new PXE server with Kickstart for deploying Ubuntu images on your LAN via bridged network mode.
It automatically detects your IP address and configures dhcpd, tftpd, etc. for you and will begin serving out the image to DCHP clients.
Fire up the VM and then PXE boot a computer on your LAN.

Change bridge to your interface if it differs.
```
config.vm.network "public_network", bridge: 'en0: Ethernet Alias'
```

You can set args a valid iso url to deploy the image of your choice.
```
config.vm.provision "shell", path: "provision.sh", args: "http://releases.ubuntu.com/14.04/ubuntu-14.04.1-server-amd64.iso"
```
