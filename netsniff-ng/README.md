Netsniff-NG Development Machine
===========

```
$ vagrant up
```

will provision a new Ubuntu Saucy VM with
 * Latest Netsniff-NG
 * Latest stable Linux Kernel
 * Gencfg sript for trafgen, and network-testing scripts
 * BPF helper tools (bpf_asm, bpf_dbg, etc.) and Perf tools

If you don't want to download and install (it takes a long time) the latest Linux
kernel set script args to 0 by editing the Vagrantfile and then up:
```
config.vm.provision "shell", path: "provision.sh", privileged: "true", args: "0"
```
Once provisioned, connect to the machine via
```
$ vagrant ssh
```
