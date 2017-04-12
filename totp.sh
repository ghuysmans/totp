#!/bin/sh
if [ "$1" = "--help" -o "$1" = "-h" ]; then
	echo usage: $0 [--dry-run] [user [host]] >&2
	exit 1
elif [ "$1" = "--dry-run" ]; then
	shift
	dry=echo
fi
if [ -z "$1" ]; then
	user=$USER
	label=$USER@$HOSTNAME
else
	user=$1
	if [ -z "$2" ]; then
		label=$1
	else
		label=$1@$2
	fi
	ssh=ssh
fi


#taken from https://wiki.archlinux.org/index.php/Pam_oath
SECRET=`head -10 /dev/urandom | md5sum | cut -b 1-30`

OATH="HOTP/T30/6 $user - $SECRET"

echo Warning: to avoid a possible disaster, open a root shell *NOW*.
prompt -p "Please type 'yes' if you want to automatically configure TOTP: " -r
if [ "$REPLY" = yes ]; then
	if ! $ssh grep -q ^otp: /etc/group; then
		if [ -z "$ssh" ]; then
			$dry sudo ./install.sh
		else
			echo "You'll have to run ./install on the remote host..."
			#TODO do this automatically?
		fi
	fi
	echo $OATH | $dry $ssh sudo tee -a /etc/security/oath.users
else
	echo $OATH | tee oath.users
fi

if which oathtool >/dev/null; then
	BASE32=`oathtool --totp -v $SECRET | sed -n "s/Base32.*: \\(.*\\)/\\1/p"`
	URI="otpauth://totp/$label?secret=$BASE32"
	echo $URI
	if which qrencode >/dev/null; then
		qrencode $URI -o qr.png
	fi
fi

oathtool --totp -w 5 $SECRET
