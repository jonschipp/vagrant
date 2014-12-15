Netsniff-NG
===========

```
$ vagrant up
```

will provision two Ubuntu Trusty VM's for testing, playing, and developing with
 * Xen w/ Ganeti (PV virtualization only)

```
$ vagrant up
$ vagrant reload
$ vagrant provision
$ vagrant ssh node1
$ gnt-node add -v -d -s 192.168.1.20 xen-node2.test
# Testing
$ /usr/lib/ganeti/tools/burnin -v -d -o debootstrap+default --disk-size=1024m --mem-size=128m -p instance{1..3}
```
