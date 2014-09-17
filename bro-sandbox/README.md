# Bro-Sandbox

````
$ vagrant up
````

will provision a machine which uses Linux Containers (LXC) via Docker containing Bro.
When a user ssh's to the demo account on the machine they're placed in a contained Linux environment.
The container lives and is re-attachable for the duration of an event (def: 3 days). The number of days
can be customized by modifying the arguments to scripts executed by /etc/cron.d/sandbox.

I wrote my own account manager (sandbox.login) to handle the creation of user containers
which can be re-attached to in the event of a disconnect, lunch break, etc.

```
$ ssh -p 2222 demo@127.0.0.1 -o UserKnownHostsFile=/dev/null
```

The password for the demo user is:
```
demo
```

## Administration & Usability

Common Tasks:

* Change the password of the demo user to help prevent unauthorized access

```
        $ passwd demo
```

* Change the password of a container user (Not a system account). Place an SHA-1 hash of the password of choice in the second field of desired user in /var/tmp/sandbox_db.

```
	$ PASS=$(echo "newpassword" | sha1sum | sed 's/ .*//)
	$ USER=testuser
	$ sed -i "/^$USER:/ s/:[^:]*/:$PASS/" /var/tmp/sandbox_db
	$ grep testuser /var/tmp/sandbox_db
	testuser:dd76770fc59bcb08cfe7951e5839ac2cb007b9e5:1410247448

```

* Configure container and user lifetime (e.g. conference duration)

  1. Specify the number of days for user account and container lifetime in:

```
        $ grep ^DAYS /usr/local/bin/sandbox_login
        DAYS=3 # Length of the event in days
```

  Removal scripts are cron jobs that are scheduled in /etc/cron.d/sandbox

* Allocate more or less resources for containers, and control other container settings.
  These changes will take effect for each newly created container.
  - System and use case dependent

```
        $ grep -A 5 "Container config" /usr/local/bin/sandbox_login
	## Container configuration (applies to each container)
	VIRTUSER=demo  # Account used when container is entered (Must exist in container!)
	CPU=1          # Number of CPU's allocated to each container
	RAM=256m       # Amount of memory allocated to each container
	HOSTNAME=bro   # Cosmetic: Will end up as $USER@$HOSTNAME:~$ in shell
	NETWORK=none   # Disable networking by default: none; Enable networking: bridge
	DNS=127.0.0.1  # Use loopback when networking is disabled to prevent error messages
```

* Set container size limit 

  - Note that for the changes to take effect you will have to wipe all existing containers and images

  1. Modify the value of dm.basesize=3G in /etc/defaults/docker

```
        $ grep basesize /etc/defaults/docker 
        DOCKER_OPTS="--dns 8.8.8.8 --dns 8.8.4.4 --storage-driver=devicemapper --storage-opt dm.basesize=3G"

        # rm -rf /var/lib/docker/
        # mkdir -p /var/lib/docker/devicemapper/devicemapper
        # restart docker
        # docker build -t jonschipp/latest-bro-sandbox - < $HOME/Dockerfile
```

* Adding, removing, or modifying exercises

  1. Make changes in /exercises on the host's filesystem

  *  Changes are immediately available for new and existing containers

## Branding

* Custom greeting upon initial system login

  1. Edit /usr/local/bin/sandbox_shell with the text of your liking

```
        #!/usr/bin/env bash
        clear
        echo "Welcome to Bro Live!"
        echo "===================="
        cat <<"EOF"
          -----------
          /             \
         |  (   (0)   )  |
         |            // |
          \     <====// /
            -----------
        EOF
        echo
        echo "A place to try out Bro."
        echo
        
        exec timeout 1m /usr/local/bin/sandbox_login
```

* Custom login message for each user

  1. Edit body of message function in /usr/local/bin/sandbox_login with the text of your liking

```
        function message {
        MESSAGE=$1
        echo
        echo "$1"
        echo "Training materials are located in /exercises."
        echo "e.g. $ bro -r /exercises/BroCon14/beginner/http.pcap"
        echo
        }
```

## Demo

Here's a brief demonstration:

```
        $ ssh demo@live.bro.org

        Welcome to Bro Live!
        ====================

            -----------
          /             \
         |  (   (0)   )  |
         |            // |
          \     <====// /
            -----------

        A place to try out Bro. 

        Are you a new or existing user? [new/existing]: new
        
        A temporary account will be created so that you can resume your session. Account is valid for the length of the event.
        
        Choose a username [a-zA-Z0-9]: jon
        Your username is jon
        Choose a password: 
        Verify your password: 
        Your account will expire on Fri 29 Aug 2014 07:40:11 PM UTC
        
        Enjoy yourself!
        Training materials are located in /exercises.
        e.g. $ bro -r /exercises/beginner/http.pcap
        
        demo@bro:~$ pwd
        /home/demo
        demo@bro:~$ which bro
        /usr/local/bro/bin/bro
```

This is a demonstration of using Linux Containers to sandbox applications for the purpose of training.
The production instance of this idea is called Bro Live! It was released at BroCon '14 <br> 
[More Information] (https://registry.hub.docker.com/u/jonschipp/latest-bro-sandbox/)
