# ISLET

````
$ vagrant up
````

will provision a machine with [ISLET](https://github.com/jonschipp/ISLET) (Isolate, Scalable, & Lightweight Environment for Training).

When a user ssh's to the demo account on the machine they're placed in a contained Linux environment designed for training.

Use:
```shell
$ ssh -p 2222 demo@127.0.0.1 -o UserKnownHostsFile=/dev/null
```

The password for the demo user is:
```
demo
```
