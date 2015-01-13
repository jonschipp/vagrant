# grsecurity

````
$ vagrant up
````

will provision a machine with grsecurity kernel.

You can set args in the Vagrantfile to your kernel version of choice (assuming corresponding grsecurity version).
```
config.vm.provision "shell", path: "provision.sh", args: "3.14.28"
```
