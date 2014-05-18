Bro-Cluster
===========

````
$ vagrant up
```

will provision a machine which Linux Containers (LXC) from a Dockerfile that have Bro installed.
When a user ssh's to the demo account on the machine they're placed in a contained Linux environment.
The environment is deleted upon termination of the SSH session.

```
$ ssh -p 2222 demo@127.0.0.1 -o UserKnownHostsFile=/dev/null
```

The password for the demo user is:
```
bro
```

This is a demonstration of using Linux Containers to sandbox applications for the purpose of conference training.
