# Cuckoo Sandbox

````
$ vagrant up
````

will provision a machine with Cuckoo sandbox using Virtualbox provider.
WUI: http://127.0.0.1/8080 (Django)
API: http://127.0.0.1/8081 (Bottle)
WUI2: http://127.0.0.1/8082 (Bottle)

Create a Windows 7 64 bit virtual machine (or other Windows OS but then set profile in /opt/cuckoo/conf/memory.conf)
````
$ scp -P 2222 -o UserKnownHostsFile=/dev/null win7.vdi root@127.0.0.1:"VirtualBox\ VMs/Cuckoo/"
$ VirtualBox # Create VM named Cuckoo, assign static IP of 192.168.56.2
$ VBoxManage snapshot "Cuckoo" take "cuckoo-snap1" --pause
$ VBoxManage controlvm "Cuckoo" poweroff
$ VBoxManage snapshot "Cuckoo" restorecurrent
$ restart cuckoo
$ /opt/cuckoo/utils/submit.py --url mobogenie.free.download.for.pc.windows.8.1.getridofadwareoncomputer.com
````

Debugging
````
$ tail -f /opt/cuckoo/log/cuckoo.log
````
