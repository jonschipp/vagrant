Bro-Sandbox
===========

````
$ vagrant up
```

will provision a machine which uses Linux Containers (LXC) via Docker containing Bro.
When a user ssh's to the demo account on the machine they're placed in a contained Linux environment.
The container lives and is re-attachable for the duration of an event (def: 3 days). The number of
can be customized by modifying the numbers in /etc/cron.d/sandbox.

I wrote my own account manager (sandbox.login) to handle the creation of user containers
which can be re-attached to in the event of a disconnect, lunch break, etc.

```
$ ssh -p 2222 demo@127.0.0.1 -o UserKnownHostsFile=/dev/null
```

The password for the demo user is:
```
demo
```

This is a demonstration of using Linux Containers to sandbox applications for the purpose of training.
