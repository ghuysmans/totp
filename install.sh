#!/bin/sh
apt-get install libpam-oath
set -e
addgroup otp
install -m 600 -t /etc/security oath oath.access oath.users
echo auth include /etc/security/oath >>/etc/pam.d/sshd
