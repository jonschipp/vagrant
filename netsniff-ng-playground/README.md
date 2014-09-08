Netsniff-NG
===========

```
$ vagrant up
```

will provision two Ubuntu Trusty VM's for testing, playing, and developing with
 * Latest Netsniff-NG
 * Latest stable Linux Kernel
 * Gencfg script for trafgen, and network-testing scripts
 * BPF helper tools (bpf_asm, bpf_dbg, etc.) and Perf tools
 * Creates an nlmon interface so one can sniff netlink messages

One VM is for sending data, the other for recieving it. (e.g. for testing trafgen)

If you don't want to download and install the latest Linux
kernel set script args to 0 by editing the Vagrantfile and then up'ing:
```
config.vm.provision "shell", path: "provision.sh", privileged: "true", args: "0"
```
Once provisioned, connect to the machine via
```
$ vagrant ssh
```
