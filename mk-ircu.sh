#!/bin/bash
if (( $EUID == 0 )); then
   echo "This script should NOT be run as root."
   echo "Running it as root will result in ircu being built in the root directory. This should NEVER be done."
   echo "Please re-run this script as the user account you wish to have ircu compiled by. Root is not a valid choice."
   read -p "Press any key to continue..."
   return 1
else
   echo "This script will attempt to build ircu. First, let's make sure the dependencies are installed."
   echo "If you are missing dependencies, you may be asked for your password to allow APT to install them."
	deps=( gcc g++ cpp flex byacc bison make autoconf automake openssl libssl-dev libpcre3-dev git )
	for i in "${deps[@]}"
	do
			if [ $(dpkg-query -W -f='${Status}' $i 2>/dev/null | grep -c "ok installed") -eq 0 ];
			then
			  echo Dependency $i is missing. Preparing to install...
			  sudo apt-get install $i;
			else
			  echo Dependency $i is already installed, skipping.;
			fi
	done
fi
echo "Ensuring we're home."
cd $HOME
echo "Downloading latest ircu source from github"
git clone https://github.com/undernetirc/ircu2
cd ircu2
echo "Configuring and building... Go enjoy a coffee!"
./configure --prefix=$HOME/IRCU_Server --enable-debug
make; make install
cd $HOME/IRCU_Server/lib
clear
echo "We need to collect some information from you to configure your ircu server."
echo "What's the name of this server? This does not need to be a FQDN. It may only be one word. No spaces."
read servername 
echo ""
echo "Now, give a description of this server."
read serverdesc 
echo ""
echo "Enter a short description for the /admin command."
read admindesc
echo ""
echo "Now some contact info for the /admin command."
read admincont
echo ""
echo "You need an IRC Operator. Autoconfig will only add one oper. You will have to add more on your own."
echo "Please specify an operator name. This will be used in the /oper command."
read opername
echo ""
echo "Now, you need a password for the /oper command. You won't see anything you type for your password, but rest assured, it is being entered."
read -s operpass
echo "Generating password hash."
operhash=$($HOME/IRCU_Server/bin/umkpasswd -m native $operpass | awk '{print $3}')
echo ""
echo "Finally, what hosts should this oper be able to oper up from?"
echo "Hosts must be set in ident@host format."
echo "You may use *@* to allow the oper to oper up from any host, but this is a security risk."
read operhost
echo ""
read -p "Do you have a website that lists other servers on your network? (y/n) " choice
case "$choice" in 
  y|Y ) read serversurl;;
  n|N ) serversurl="This is the only server on this network";;
  * ) serversurl="This is the only server on this network" | echo "Invalid choice. Defaulting to no.";;
esac
clear
echo "Autogenerating ircu configuration. This will only take a moment..." 
cat <<IRCD_CONF > ircd.conf
General {
	name = "${servername}";
	description = "${serverdesc}";
	numeric = 1;
};
Admin {
	Location = "${servername}";
	Location = "${admindesc}";
	Contact = "${admincont}";
};
Class {
 name = "Server";
 pingfreq = 1 minutes 30 seconds;
 connectfreq = 5 minutes;
 maxlinks = 1;
 sendq = 9000000;
};
Class {
 name = "LeafServer";
 pingfreq = 1 minutes 30 seconds;
 connectfreq = 5 minutes;
 maxlinks = 0;
 sendq = 9000000;
};
Class {
 name = "Local";
 pingfreq = 1 minutes 30 seconds;
 sendq = 160000;
 maxlinks = 100;
 usermode = "+iw";
};
Class {
 name = "America";
 pingfreq = 1 minutes 30 seconds;
 sendq = 80000;
 maxlinks = 5;
};
Class {
 name = "Other";
 pingfreq = 1 minutes 30 seconds;
 sendq = 160000;
 maxlinks = 400;
};
Class {
 name = "Opers";
 pingfreq = 1 minutes 30 seconds;
 sendq = 160000;
 maxlinks = 10;
 local = no;
 whox = yes;
 display = yes;
 chan_limit = yes;
 mode_lchan = yes;
 deop_lchan = yes;
 walk_lchan = yes;
 show_invis = yes;
 show_all_invis = yes;
 unlimit_query = yes;
 local_kill = yes;
 rehash = yes;
 restart = yes;
 die = yes;
 local_jupe = yes;
 set = yes;
 local_gline = yes;
 local_badchan = yes;
 see_chan = yes; 
 list_chan = yes; 
 wide_gline = yes;
 see_opers = yes;
 local_opmode = yes;
 force_local_opmode = yes;
 kill = yes;
 gline = yes;
 opmode = yes; 
 badchan = yes;
 force_opmode = yes;
 apass_opmode = yes; 
};
Client
{
 class = "Other";
 ip = "*@*";
 maxlinks = 20;
};
Client
{
 class = "Other";
 host = "*@*";
 maxlinks = 20;
};
Client
{
 host = "*@*.com";
 class = "America";
 maxlinks = 2;
};
Client
{
 host = "*@*.net";
 class = "America";
 maxlinks = 2;
};
Client
{
 host = "*@localhost";
 ip = "*@127.0.0.1";
 class = "Local";
 # A maxlinks of over 5 will automatically be glined by euworld
 maxlinks = 5;
};
Client {
 host = "*@*";
 ip = "*@*";
 class = "Other";
 maxlinks = 2;
};
motd {
 host = "*.net";
 file = "net_com.motd";
};
motd {
 host = "*.com";
 file = "net_com.motd";
};
motd {
 host = "America";
 file = "net_com.motd";
};
motd {
 host = "*.london.ac.uk";
 file = "london.motd";
};
UWorld {
	name = "services.undernet.org";
};
Jupe {
 nick = "A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,{,|,},~,-,_,\`";
 nick = "EuWorld,UWorld,UWorld2";
 nick = "login,undernet,protocol,pass,newpass,org";
 nick = "StatServ,NoteServ";
 nick = "ChanSvr,ChanSaver,ChanServ";
 nick = "NickSvr,NickSaver,NickServ";
 nick = "LPT1,LPT2,COM1,COM2,COM3,COM4,AUX";
};
Kill { host = "*.au"; reason = "Please use a nearer server"; };
Kill { host = "*.edu"; reason = "Please use a nearer server"; };
##### EDIT THIS TO LINK X #####
Connect {
  name = "services.undernet.org";
  host = "127.0.0.1";
  password = "54321";
  port = 4400;
  class = "Server";
  autoconnect = no;
  hub = "*";
};
Operator {
  host = "${operhost}";
  password = "${operhash}";
  name = "${opername}";
  class = "Opers";
};
Port {
 server = yes;
 port = 4400;
};
Port {
 server = yes;
 hidden = yes;
 port = ipv4 4401;
};
Port { port = 6667; };
Port { port = 6668; };
Port {
 vhost = "172.16.0.1" 6667;
 vhost = "172.16.3.1" 6668;
 hidden = no;
};
Quarantine {
  "#COVID-19" = "Maintain social distancing of 6ft or more. Wear a mask.";
};
Pseudo "CHANSERV" {
	name = "X";
	nick = "X@services.undernet.org";
};
Pseudo "LOGIN" {
	name = "X";
	prepend = "LOGIN ";
	nick = "X@services.undernet.org";
};
WebIRC {
 ip = "1.2.3.4";  # may be a netmask, e.g. 1.2.3.4/28
 password = "webirc-secret";
 description = "some webirc client";
 hidden = yes; # hides IP in /stats webirc
};
features
{
# These log features are the only way to get certain error messages
# (such as when the server dies from being out of memory).  For more
# explanation of how they work, see doc/readme.log.
 "LOG" = "SYSTEM" "FILE" "ircd.log";
 "LOG" = "SYSTEM" "LEVEL" "CRIT";
#  "DOMAINNAME"="undernet-server.local";
#  "RELIABLE_CLOCK"="FALSE";
#  "BUFFERPOOL"="27000000";
#  "HAS_FERGUSON_FLUSHER"="FALSE";
#  "CLIENT_FLOOD"="1024";
#  "SERVER_PORT"="4400";
#  "NODEFAULTMOTD"="TRUE";
#  "MOTD_BANNER"="TRUE";
#  "KILL_IPMISMATCH"="FALSE";
#  "IDLE_FROM_MSG"="TRUE";
#  "HUB"="FALSE";
#  "WALLOPS_OPER_ONLY"="FALSE";
#  "NODNS"="FALSE";
#  "RANDOM_SEED"="Undernet.USER";
#  "DEFAULT_LIST_PARAM"="TRUE";
#  "NICKNAMEHISTORYLENGTH"="800";
  "NETWORK"="${servername}";
  "HOST_HIDING"="TRUE";
  "HIDDEN_HOST"="users.undernet.org";
  "HIDDEN_IP"="127.0.0.1";
#  "KILLCHASETIMELIMIT"="30";
#  "MAXCHANNELSPERUSER"="10";
#  "NICKLEN" = "12";
#  "AVBANLEN"="40";
#  "MAXBANS"="30";
#  "MAXSILES"="15";
#  "HANGONGOODLINK"="300";
# "HANGONRETRYDELAY" = "10";
# "CONNECTTIMEOUT" = "90";
# "MAXIMUM_LINKS" = "1";
# "PINGFREQUENCY" = "120";
# "CONNECTFREQUENCY" = "600";
# "DEFAULTMAXSENDQLENGTH" = "40000";
# "GLINEMAXUSERCOUNT" = "20";
# "MPATH" = "ircd.motd";
# "RPATH" = "remote.motd";
# "PPATH" = "ircd.pid";
# "TOS_SERVER" = "0x08";
# "TOS_CLIENT" = "0x08";
# "POLLS_PER_LOOP" = "200";
# "IRCD_RES_TIMEOUT" = "4";
# "IRCD_RES_RETRIES" = "2";
# "AUTH_TIMEOUT" = "9";
# "IPCHECK_CLONE_LIMIT" = "4";
# "IPCHECK_CLONE_PERIOD" = "40";
# "IPCHECK_CLONE_DELAY" = "600";
# "CHANNELLEN" = "200";
# "CONFIG_OPERCMDS" = "FALSE";
# "OPLEVELS" = "TRUE";
# "ZANNELS" = "TRUE";
# "LOCAL_CHANNELS" = "TRUE";
# "ANNOUNCE_INVITES" = "TRUE";
#  These were introduced by Undernet CFV-165 to add "Head-In-Sand" (HIS)
#  behavior to hide most network topology from users.
#  "HIS_SNOTICES" = "TRUE";
#  "HIS_SNOTICES_OPER_ONLY" = "TRUE";
#  "HIS_DEBUG_OPER_ONLY" = "TRUE";
#  "HIS_WALLOPS" = "TRUE";
#  "HIS_MAP" = "TRUE";
#  "HIS_LINKS" = "TRUE";
#  "HIS_TRACE" = "TRUE";
#  "HIS_STATS_a" = "TRUE";
#  "HIS_STATS_c" = "TRUE";
#  "HIS_STATS_d" = "TRUE";
#  "HIS_STATS_e" = "TRUE";
#  "HIS_STATS_f" = "TRUE";
#  "HIS_STATS_g" = "TRUE";
#  "HIS_STATS_i" = "TRUE";
#  "HIS_STATS_j" = "TRUE";
#  "HIS_STATS_J" = "TRUE";
#  "HIS_STATS_k" = "TRUE";
#  "HIS_STATS_l" = "TRUE";
#  "HIS_STATS_L" = "TRUE";
#  "HIS_STATS_m" = "TRUE";
#  "HIS_STATS_M" = "TRUE";
#  "HIS_STATS_o" = "TRUE";
#  "HIS_STATS_p" = "TRUE";
#  "HIS_STATS_q" = "TRUE";
#  "HIS_STATS_r" = "TRUE";
#  "HIS_STATS_R" = "TRUE";
#  "HIS_STATS_t" = "TRUE";
#  "HIS_STATS_T" = "TRUE";
#  "HIS_STATS_u" = "FALSE";
#  "HIS_STATS_U" = "TRUE";
#  "HIS_STATS_v" = "TRUE";
#  "HIS_STATS_w" = "TRUE";
#  "HIS_STATS_W" = "TRUE";
#  "HIS_STATS_x" = "TRUE";
#  "HIS_STATS_y" = "TRUE";
#  "HIS_STATS_z" = "TRUE";
#  "HIS_STATS_IAUTH" = "TRUE";
#  "HIS_WEBIRC" = "TRUE";
#  "HIS_WHOIS_SERVERNAME" = "TRUE";
#  "HIS_WHOIS_IDLETIME" = "TRUE";
#  "HIS_WHOIS_LOCALCHAN" = "TRUE";
#  "HIS_WHO_SERVERNAME" = "TRUE";
#  "HIS_WHO_HOPCOUNT" = "TRUE";
#  "HIS_MODEWHO" = "TRUE";
#  "HIS_BANWHO" = "TRUE";
#  "HIS_KILLWHO" = "TRUE";
#  "HIS_REWRITE" = "TRUE";
#  "HIS_REMOTE" = "TRUE";
#  "HIS_NETSPLIT" = "TRUE";
  "HIS_SERVERNAME" = "*.${servername}.undernet.org";
  "HIS_SERVERINFO" = "${serverdesc}";
  "HIS_URLSERVERS" = "${serversurl}";
#  "URLREG" = "#cservice";
};
IRCD_CONF
rm example.conf
clear
echo "And that's it. You should have a fully functional ircu server now. Happy IRCing!"
echo "Keep in mind, autoconfig doesn't produce a fully customized ircu configuration file."
echo ""
echo "There are many other options that autoconfig does not modify. It is up to you as the"
echo "administrator of this newly built server to modify them to your desire."
