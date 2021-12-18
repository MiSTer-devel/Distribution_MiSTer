#!/bin/bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Copyright 2019 Alessandro "Locutus73" Miele

# You can download the latest version of this script from:
# https://github.com/MiSTer-devel/Distribution_MiSTer

# Version 2.1 - 2021-12-17 - Fixes from Kreeblah for 5.x kernel and authorized_keys feature
# Version 2.0 - 2021-08-30 - Tests if executed on a 5.X Kernel system (thanks to MiSTer Addons for the help with testing).
# Version 1.3.4 - 2021-03-22 - Refined the check for standard root password.
# Version 1.3.3 - 2021-02-21 - Changed https://curl.haxx.se/ca/cacert.pem to https://curl.se/ca/cacert.pem and added option to follow redirects.
# Version 1.3.2 - 2020-12-07 - Refined the check for standard root password.
# Version 1.3.1 - 2020-05-03 - Refined the check for standard root password.
# Version 1.3 - 2019-06-16 - Remounting root filesystem RW (and back RO) when needed, for making the script compatible with the new Framebuffer Terminal.
# Version 1.2.10 - 2019-06-10 - Testing Internet connectivity with github.com instead of google.com; refined the check for standard root password.
# Version 1.2.9 - 2019-06-03 - Refined the check for standard root password.
# Version 1.2.8 - 2019-05-27 - Refined the check for standard root password.
# Version 1.2.7 - 2019-05-25 - Refined the check for standard root password.
# Version 1.2.6 - 2019-05-11 - Refined the check for standard root password.
# Version 1.2.5 - 2019-05-02 - Code review by makigumo, now the script runs from any terminal, not only SSH, thank you very much.
# Version 1.2.4 - 2019-04-08 - Refined the check for standard root password.
# Version 1.2.3 - 2019-04-04 - Refined the check for standard root password.
# Version 1.2.2 - 2019-04-03 - Updated openssl deb package URL.
# Version 1.2.1 - 2019-02-06 - Refined the check for standard root password.
# Version 1.2 - 2019-02-06 - Added security fix for Samba minimum allowed protocol.
# Version 1.1.1 - 2019-02-06 - Changed the name of the repository Kernel file to zImage_dtb_socfpga-4.5.
# Version 1.1 - 2019-02-06 - Checking current Kernel release is 4.5.0-socfpga-r1 before updating it for firewalling/iptables support.
# Version 1.0.1 - 2019-02-05 - Cosmetic changes.
# Version 1.0 - 2019-02-02 - First commit



KERNEL_VERSION="$(uname -r)"
KERNEL_VERSION="${KERNEL_VERSION%%-*}"
if [[ "${KERNEL_VERSION}" < "5.0.0" ]]
then
	echo "This script requires your MiSTer"
	echo "system use the current 5.X Kernel."
	echo "Please update your system and re-run"
	echo "this script."
	exit 1
fi
if [ "$(uname -n)" != "MiSTer" ]
then
	echo "This script must be run"
	echo "on a MiSTer system."
	exit 1
fi
if [[ ! (-t 0 && -t 1 && -t 2) ]]
then
	echo "This script must be run"
	echo "from a SSH/UART terminal"
	echo "because it will ask"
	echo "some questions."
	exit 2
fi
if (( $EUID != 0 )); then
    echo "This script must be run as root."
    exit 3
fi

mount | grep "on / .*[(,]ro[,$]" -q && RO_ROOT="true"

if [[ (-d /root/.ssh && ("$(stat -c "%a" "/root/.ssh")" -ne 700) || ("$(stat --format "%U" "/root/.ssh")" != "root") || ("$(stat --format "%G" "/root/.ssh")" != "root")) || (! -d /root/.ssh) || (-f /root/.ssh/authorized_keys && ("$(stat -c "%a" "/root/.ssh/authorized_keys")" -ne 600) || ("$(stat --format "%U" "/root/.ssh/authorized_keys")" != "root") || ("$(stat --format "%G" "/root/.ssh/authorized_keys")" != "root")) || (! -f /root/.ssh/authorized_keys) ]]; then
	echo "authorized_keys does not exist or does"
	echo "not have the correct permissions, and"
	echo "should be fixed."
	if [[ $RO_ROOT == "true" ]]; then
		echo ""
		echo "root fs is mounted ro."
		echo "rerun after remounting root fs"
		echo "in order to fix."
		echo ""
	else
		read -p "Do you want to fix it? [y|n]" -n 1 -r
		echo ""
		case "$REPLY" in
			y|Y)
				if [[ ! -d /root/.ssh ]]; then
					mkdir /root/.ssh
				fi
				chown root:root /root/.ssh
				chmod 700 /root/.ssh

				if [[ ! -f /root/.ssh/authorized_keys ]]; then
					if [[ -f /media/fat/config/authorized_keys ]]; then
						cp /media/fat/config/authorized_keys /root/.ssh/authorized_keys
					else
						touch /root/.ssh/authorized_keys
					fi
				fi
				chown root:root /root/.ssh/authorized_keys
				chmod 600 /root/.ssh/authorized_keys

				sync
				echo "authorized_keys permissions fixed."
		esac
	fi
else
	echo "authorized_keys permissions ok."
fi

echo ""

unset MISTER_PWD_TEST
MISTER_DEFAULT_PASSWORD=1

IFS=':' read -ra MISTER_ETC_SHADOW <<< `grep -o "^root:[^:]*" /etc/shadow`
if [[ ${MISTER_ETC_SHADOW[1]} = \$* ]]; then
	MISTER_PWD_TEST=${MISTER_ETC_SHADOW[1]}
fi

if [[ -z $MISTER_PWD_TEST ]]; then
	echo "unable to check root password."
	echo "verify that /etc/shadow exists and"
	echo "has valid contents."
else
	IFS='$' read -ra MISTER_ROOT_PWD <<< "$MISTER_PWD_TEST"
	MISTER_PWD_GENERATED=`openssl passwd -${MISTER_ROOT_PWD[1]} -salt "${MISTER_ROOT_PWD[2]}" $MISTER_DEFAULT_PASSWORD`

	if [[ $MISTER_PWD_TEST = $MISTER_PWD_GENERATED ]]; then
		echo "root password is the original one from"
		echo "the SD-Installer; it should be changed."
		read -p "Do you want me to fix it?? [y|n]" -n 1 -r
		echo ""
		case "$REPLY" in
			y|Y)
				[ "$RO_ROOT" == "true" ] && mount / -o remount,rw
				until passwd root
				do
					echo "Password not set, try again."
					sleep 1
				done
				sync
				[ "$RO_ROOT" == "true" ] && mount / -o remount,ro
				echo "root password succesfully changed."
				;;
		esac
	else
		echo "root password has already been changed."
	fi
fi

echo ""
curl -q https://github.com &>/dev/null
case $? in
	0)
		echo "CA certificates seem to work, no fix will be applied."
		;;
	60)
		read -p "CA certificates need to be fixed, do you want me to fix them? [y|n]" -n 1 -r
		echo ""
		case "$REPLY" in
			y|Y)
				[ "$RO_ROOT" == "true" ] && mount / -o remount,rw
				if  (( $(ls -A /etc/ssl/certs| wc -l) > 0 ))
				then
					echo "/etc/ssl/certs is not empty, please backup its content first and then empty it."
					read -p "Do you want me to empty /etc/ssl/certs? [y|n]" -n 1 -r
					echo ""
					case "$REPLY" in
						y|Y)
							rm /etc/ssl/certs/*
							;;
						*)
							exit 4
							;;
					esac
				fi
				echo "Downloading and processing https://curl.se/ca/cacert.pem into /etc/ssl/certs;"
				echo "this may take some time..."
				curl -kL "https://curl.se/ca/cacert.pem"|awk 'split_after==1{n++;split_after=0} /-----END CERTIFICATE-----/ {split_after=1} {if(length($0) > 0) print > "/etc/ssl/certs/cert" n ".pem"}'
				for PEM in /etc/ssl/certs/*.pem; do mv "$PEM" "$(dirname "$PEM")/$(cat "$PEM" | grep -m 1 '^[^#]').pem"; done
				for PEM in /etc/ssl/certs/*.pem; do for HASH in $(openssl x509 -subject_hash_old -hash -noout -in "$PEM" 2>/dev/null); do ln -s "$(basename "$PEM")" "$(dirname "$PEM")/$HASH.0"; done; done
				sync
				[ "$RO_ROOT" == "true" ] && mount / -o remount,ro
				echo "CA certificates have been successfully fixed."
				;;
			esac
		;;
	*)
		echo "No Internet connection, please try again later."
		;;
esac

echo ""
if [ "$(/usr/bin/ssh-keygen -l -f /etc/ssh/ssh_host_rsa_key.pub)" == "2048 SHA256:eDrKAiW7GupcPO/m5f3Rwuo2lJeOPemY7do8nomM5bY root@de10-nano (RSA)" ]
then
	echo "SSH host keys are the original ones which came"
	echo "with the SD-Installer; they should be regenerated."
	read -p "Do you want me to fix them? [y|n]" -n 1 -r
	echo ""
	case "$REPLY" in
		y|Y)
			echo "Generating new SSH host keys."
			echo "Next time you connect through SSH or SCP"
			echo "your client will warn you MiSTer host keys"
			echo "don't match to the cached ones: it's normal,"
			echo "it's the whole point of the procedure."
			echo "Please say YES to PuTTY, UPDATE to WinSCP or"
			echo "run something like \"ssh-keygen -R MiSTer\""
			echo "on your Linux/BSD/OSX machine."
			
			[ "$RO_ROOT" == "true" ] && mount / -o remount,rw
			rm /etc/ssh/ssh_host_*
			echo "Creating new SSH host keys; this may take some time..."
			ssh-keygen -A
			sync
			[ "$RO_ROOT" == "true" ] && mount / -o remount,ro
			echo "SSH host keys have been successfully fixed."
			;;
	esac
else
	echo "SSH host keys seem to be already regenerated, no fix will be applied."
fi

echo ""
if [ -f /etc/init.d/S50sshd ];
then
	echo "SSH daemon is active at startup;"
	echo "it should be inactive by default"
	echo "and manually activated when needed"
	echo "(i.e. using auxillary ssh_on.sh)."
	read -p "Do you want me to fix it?? [y|n]" -n 1 -r
	echo ""
	case "$REPLY" in
		y|Y)
			[ "$RO_ROOT" == "true" ] && mount / -o remount,rw
			mv /etc/init.d/S50sshd /etc/init.d/_S50sshd > /dev/null 2>&1
			if [ -f /media/fat/linux/iptables.up.rules ]
			then
				sed -e '/--dport 22 /s/^#*/#/g' -i /media/fat/linux/iptables.up.rules
			fi
			sync
			[ "$RO_ROOT" == "true" ] && mount / -o remount,ro
			echo "Now SSH is inactive at startup."
			;;
	esac
else
	echo "SSH daemon is correctly inactive at startup."
fi

echo ""
if [ -f /etc/init.d/S50proftpd ];
then
	echo "FTP daemon is active at startup;"
	echo "it should be inactive by default"
	echo "and manually activated when needed"
	echo "(i.e. using auxillary ftp_on.sh)."
	read -p "Do you want me to fix it?? [y|n]" -n 1 -r
	echo ""
	case "$REPLY" in
		y|Y)
			[ "$RO_ROOT" == "true" ] && mount / -o remount,rw
			mv /etc/init.d/S50proftpd /etc/init.d/_S50proftpd > /dev/null 2>&1
			if [ -f /media/fat/linux/iptables.up.rules ]
			then
				sed -e '/--dport 21 /s/^#*/#/g' -i /media/fat/linux/iptables.up.rules
			fi
			sync
			[ "$RO_ROOT" == "true" ] && mount / -o remount,ro
			echo "Now FTP is inactive at startup."
			;;
	esac
else
	echo "FTP daemon is correctly inactive at startup."
fi

echo ""
if [ -f /etc/init.d/S91smb ];
then
	echo "Samba daemon is active at startup;"
	echo "it should be inactive by default"
	echo "and manually activated when needed"
	echo "(i.e. using auxillary ssh_on.sh)."
	read -p "Do you want me to fix it?? [y|n]" -n 1 -r
	echo ""
	case "$REPLY" in
		y|Y)
			[ "$RO_ROOT" == "true" ] && mount / -o remount,rw
			mv /etc/init.d/S91smb /etc/init.d/_S91smb > /dev/null 2>&1
			if [ -f /media/fat/linux/iptables.up.rules ]
			then
				sed -e '/--dport 137 /s/^#*/#/g' -i /media/fat/linux/iptables.up.rules
				sed -e '/--dport 138 /s/^#*/#/g' -i /media/fat/linux/iptables.up.rules
				sed -e '/--dport 139 /s/^#*/#/g' -i /media/fat/linux/iptables.up.rules
				sed -e '/--dport 445 /s/^#*/#/g' -i /media/fat/linux/iptables.up.rules
			fi
			sync
			[ "$RO_ROOT" == "true" ] && mount / -o remount,ro
			echo "Now Samba is inactive at startup."
			;;
		*)
			if [ ! -f /media/fat/linux/samba.sh ]
			then
				echo "Samba will try to activate at startup, but it won't"
				echo "because you have still to manually rename /media/fat/linux/_samba.sh"
				echo "to /media/fat/linux/samba.sh and customize it."
			fi
			;;
	esac
else
	echo "Samba daemon is correctly inactive at startup."
fi

echo ""
if ! grep -q "min protocol" /etc/samba/smb.conf
then
	echo "Samba minimum allowed protocol isn't configured;"
	echo "it should be configured at least for SMB2".
	read -p "Do you want me to fix it?? [y|n]" -n 1 -r
	echo ""
	case "$REPLY" in
		y|Y)
			[ "$RO_ROOT" == "true" ] && mount / -o remount,rw
			sed '/\[global\]/a\\n   min protocol = SMB2\n' -i /etc/samba/smb.conf
			sync
			[ "$RO_ROOT" == "true" ] && mount / -o remount,ro
			echo "Now Samba is configured with \"min protocol = SMB2\"."
			;;
		*)
			;;
	esac
else
	echo "Samba minimum allowed protocol is already configured."
	grep "min protocol" /etc/samba/smb.conf
	echo "Please be sure it's at least SMB2."
fi

echo ""
if { ! iptables -L > /dev/null 2>&1; } || [ ! -f /media/fat/linux/iptables.up.rules ] || [ ! -f /etc/network/if-pre-up.d/iptables ]
then
	echo "Firewall is not enabled and/or configured;"
	echo "it should be active letting only active"
	echo "daemons to be reached from the outside."
	read -p "Do you want me to fix it?? [y|n]" -n 1 -r
	echo ""
	case "$REPLY" in
		y|Y)
			if [ ! -f /media/fat/linux/iptables.up.rules ]
			then
				IPTABLES_UP_RULES="*filter"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# Allows all loopback (lo0) traffic and drop all traffic to 127/8 that doesn't use lo0"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -i lo -j ACCEPT"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT ! -i lo -d 127.0.0.0/8 -j REJECT"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# Accepts all established inbound connections"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# Allows all outbound traffic"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# You could modify this to only allow certain traffic"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A OUTPUT -j ACCEPT"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# Allows SSH connections"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# The --dport number is the same as in /etc/ssh/sshd_config"
				if [ -f /etc/init.d/S50sshd ]
				then
					IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -p tcp -m state --state NEW --dport 22 -j ACCEPT"
				else
					IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"#-A INPUT -p tcp -m state --state NEW --dport 22 -j ACCEPT"
				fi
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# Now you should read up on iptables rules and consider whether ssh access"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# for everyone is really desired. Most likely you will only allow access from certain IPs."
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# Allows FTP connections"
				if [ -f /etc/init.d/S50proftpd ]
				then
					IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -p tcp -m state --state NEW --dport 21 -j ACCEPT"
				else
					IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"#-A INPUT -p tcp -m state --state NEW --dport 21 -j ACCEPT"
				fi
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# Allows Samba connections"
				if [ -f /etc/init.d/S91smb ]
				then
					IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -p udp -m state --state NEW --dport 137 -j ACCEPT"
					IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -p udp -m state --state NEW --dport 138 -j ACCEPT"
					IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -p tcp -m state --state NEW --dport 139 -j ACCEPT"
					IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -p tcp -m state --state NEW --dport 445 -j ACCEPT"
				else
					IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"#-A INPUT -p udp -m state --state NEW --dport 137 -j ACCEPT"
					IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"#-A INPUT -p udp -m state --state NEW --dport 138 -j ACCEPT"
					IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"#-A INPUT -p tcp -m state --state NEW --dport 139 -j ACCEPT"
					IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"#-A INPUT -p tcp -m state --state NEW --dport 445 -j ACCEPT"
				fi
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# Allow ping"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"#  note that blocking other types of icmp packets is considered a bad idea by some"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"#  remove -m icmp --icmp-type 8 from this line to allow all kinds of icmp:"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"#  https://security.stackexchange.com/questions/22711"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# log iptables denied calls (access via 'dmesg' command)"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -m limit --limit 5/min -j LOG --log-prefix \"iptables denied: \" --log-level 7"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# Reject all other inbound - default deny unless explicitly allowed policy:"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -j REJECT"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A FORWARD -j REJECT"
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
				IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"COMMIT"
				echo "$IPTABLES_UP_RULES" > /media/fat/linux/iptables.up.rules
			fi
			if [ ! -f /etc/network/if-pre-up.d/iptables ]
			then
				[ "$RO_ROOT" == "true" ] && mount / -o remount,rw
				echo "#!/bin/bash"$'\n'"iptables-restore < /media/fat/linux/iptables.up.rules" > /etc/network/if-pre-up.d/iptables
				chmod +x /etc/network/if-pre-up.d/iptables
				[ "$RO_ROOT" == "true" ] && mount / -o remount,ro
			fi
			sync
			echo "Now Firewall is active at startup."
		;;
	esac
else
	echo "Firewall is correctly active and configured."
fi

echo ""
echo "Done!"
echo "You can reboot now for actually applying changes."

exit 0