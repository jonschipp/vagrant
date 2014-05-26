Netsniff-NG
===========

```
$ vagrant up
```

will provision a new Ubuntu Saucy VM for testing, playing, and developing with
 * Latest Netsniff-NG
 * Latest stable Linux Kernel
 * Gencfg script for trafgen, and network-testing scripts
 * BPF helper tools (bpf_asm, bpf_dbg, etc.) and Perf tools
 * Creates an nlmon interface so one can sniff netlink messages

If you don't want to download and install the latest Linux
kernel set script args to 0 by editing the Vagrantfile and then up'ing:
```
config.vm.provision "shell", path: "provision.sh", privileged: "true", args: "0"
```
Once provisioned, connect to the machine via
```
$ vagrant ssh
```
