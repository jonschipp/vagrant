#!/bin/bash
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
sh -c "echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
apt-get update
apt-get -y install lxc-docker expect

docker build -t sandbox - < Dockerfile
#docker commit $(docker ps -a -q | head -n 1) sandbox

cat > /usr/local/bin/sandbox <<EOF
#!/bin/sh
exec sudo docker run -t -h bro -c 1 -m 100m -i --rm=true sandbox /bin/bash -c 'su - demo'
EOF

cat > /etc/sudoers.d/sandbox <<EOF
Cmnd_Alias SANDBOX = /usr/bin/docker
demo ALL=(root) NOPASSWD: SANDBOX
EOF

chmod 0440 /etc/sudoers.d/sandbox
chmod a+x /usr/local/bin/sandbox
sh -c 'echo /usr/local/bin/sandbox >> /etc/shells'
adduser --disabled-login --gecos "" --shell /usr/local/bin/sandbox demo

/usr/bin/expect <<EOF
spawn /usr/bin/passwd demo
expect "password:"
send "demo\n"
expect "password:"
send "demo\n"
expect eof
EOF
