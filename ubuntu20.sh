## run ubuntu20.sh >log 2>errors 
## orginal was for Ubuntu but have switch to stock debian because of ubuntu new installer
## the ISO sets up the main user as media - this script follows that user
####install auto=true url=https://yoururl.com/seed/preseed.cfg hostname=homeserver domain=local
sudo apt install -y lsb-release apt-transport-https dnsutils ca-certificates software-properties-common
## must have packages for this script to install 
sudo apt install -y beep genisoimage libarchive-tools syslinux-utils wget sharutils sudo gnupg ca-certificates curl git dirmngr htop
##I don't use or see a purpose for the below - the server is locked into only being a media server - if your going to modify then add them back in.
sudo apt purge apparmor cloud-init snapd -y
rm -Rv /var/cache/apparmor 
rm -Rv /etc/apparmor.d/local 
sudo usermod -aG sudo media
#adding tunnel user - vpn to split tunnel transmission on VPN side for torrent protection
sudo adduser --disabled-login --gecos "" vpn
# allowing Media user and VPN to interact 
sudo adduser media vpn
sudo adduser vpn media
## Edit system for VPN and transmission-daemon transfer rates - transmission complains if these arent't set
cat <<EOF >> /etc/sysctl.conf
net.ipv4.ip_forward=1
net.core.rmem_default = 1048576
net.core.rmem_max = 16777216
net.core.wmem_default = 1048576
net.core.wmem_max = 16777216
net.core.optmem_max = 65536
net.ipv4.tcp_rmem = 4096 1048576 2097152
net.ipv4.tcp_wmem = 4096 65536 16777216
EOF
## mods for VPN tunneling 
cat > /etc/sysctl.d/9999-vpn.conf <<SYS
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
net.ipv4.conf.enp2s0.rp_filter = 2
SYS
cat <<EOT >> /etc/iproute2/rt_tables
200     vpn
EOT
sudo sysctl -p
#script for dynamip IP and VPN info after boot and writing it to nginx and openvpn scripts
cat << 'SYS' >/etc/network/if-up.d/netipvpn
#!/bin/bash
dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}' > /home/media/IFINFO
mainnet=$(ip route get 8.8.8.8 | awk -- '{printf $5}')
vpn2=$(ip addr show tun0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
vpn1=$(ip addr show $mainnet | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
## store info in file for review or use 
echo $vpn2 >> /home/media/IFINFO
echo $vpn1 >> /home/media/IFINFO
echo $mainnet >> /home/media/IFINFO
chmod 777 /home/media/IFINFO
##update nginx with transmission vpn ip route
sed -i -e "/.*:9091/s/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/$vpn1/g" /etc/nginx/sites-available/default
exit 0
SYS
chmod +x /etc/network/if-up.d/netipvpn
touch /home/media/IFINFO
## install nodejs v12 - don't go above 12 - problems with youtubedl-material
curl -sL https://deb.nodesource.com/setup_15.x | sudo -E bash -
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add -
echo "deb https://downloads.plex.tv/repo/deb public main" | tee  /etc/apt/sources.list.d/plexserver.list;
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8
echo "deb https://apt.sonarr.tv/debian buster main" | sudo tee /etc/apt/sources.list.d/sonarr.list
sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
apt update
##uncomment next lines if you want virtual machine installed
#apt install -y qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager
#adduser media libvirt
#adduser media libvirt-qemu
##Things needed to make it all work together
apt install -y unzip zip unrar ffmpeg mono-devel tmux transmission-daemon debconf-utils openvpn openvpn-systemd-resolved apt-utils iptables
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install iptables-persistent
##Istalling Nginx and PHP for simple webpage also included mysql plugins
apt install -y nginx php7.4 php7.4-common php7.4-cli php7.4-fpm  --allow-unauthenticated;
apt install -y php7.4-mysql php7.4-gd php7.4-json php7.4-curl php7.4-zip php7.4-xml php7.4-mbstring php7.4-pgsql php7.4-bcmath;
#apt install -y mariadb-server ##if you need it
apt install -y python3-pip  python-dev python-lxml libminiupnpc-dev miniupnpc
apt install -y build-essential libssl-dev python3-dbus python3-augeas python3-apt ntpdate
apt install -y libxml2-dev libffi-dev libjpeg-dev libpng-dev uuid-dev python-dbus;
sudo DEBIAN_FRONTEND=noninteractive apt install -y samba
sudo apt install -y sqlite3 fail2ban mediainfo cifs-utils smbclient dos2unix avahi-daemon avahi-discover avahi-utils libnss-mdns mdns-scan
systemctl stop transmission-daemon
## Switch Transmission over to VPN user 
## and setup transmission for split tunnel save the orginal if you want to go back 
mv /lib/systemd/system/transmission-daemon.service /home/media/transmission-daemon.service.original
cat <<'EOF'>/lib/systemd/system/transmission-daemon.service
[Unit]
Description=Transmission BitTorrent Daemon
#After=network.target
## uncomment above an comment out two below if you want to run without vpn
After=sys-devices-virtual-net-tun0.device
Wants=sys-devices-virtual-net-tun0.device
[Service]
#User=debian-transmission
User=vpn
Group=vpn
Type=simple
ExecStart=/usr/bin/transmission-daemon -f --log-error -g /etc/transmission-daemon
ExecStop=/bin/kill -s STOP $MAINPID
ExecReload=/bin/kill -s HUP $MAINPID
Restart=on-failure
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
sudo chown -R vpn:vpn /etc/transmission-daemon/
sudo chown -R vpn:vpn /var/lib/transmission-daemon/
sudo chmod -R 775 /etc/transmission-daemon/
sudo chmod -R 775 /var/lib/transmission-daemon/
sed -i '/"rpc-authentication-required": *true/ s/true/false/' /etc/transmission-daemon/settings.json
sed -i '/"rpc-host-whitelist-enabled": *true/ s/true/false/'  /etc/transmission-daemon/settings.json
sed -i '/"rpc-whitelist-enabled": *true/ s/true/false/'  /etc/transmission-daemon/settings.json
sed -i '/"script-torrent-done-enabled": *false/ s/false/true' /etc/transmission-daemon/settings.json
sed -i '/"script-torrent-done-filename": ""/c         "script-torrent-done-filename": "/home/vpn/unpack.sh",' /etc/transmission-daemon/settings.json
## create an auto unrar script for transmission to unpack completed torrents
cat <<'EOF' >/home/vpn/unpack.sh
#!/bin/bash
######################
TR_TORRENT_DIR=${TR_TORRENT_DIR:-$1}
TR_TORRENT_NAME=${TR_TORRENT_NAME:-$2}
torrentPath=${TR_TORRENT_DIR}/${TR_TORRENT_NAME}
log_prefix="Transmission-Daemon"
_log() {
  logger -t ${log_prefix} "$@"
}
_find_rars () {
  find "${1}" -type -f \( -iname \*.rar  -o -iname \*.part1.rar -o -iname \*.part01.rar \)
}
_unrar_torrent () {
  find "${1}" \( -iname \*.rar -o -iname \*.part1.rar -o -iname \*.part01.rar \)  -execdir unrar e {} "${2}" ";"
}
_log "$TR_TORRENT_NAME is finished, processing directory for unpacking"
if [ -f "${torrentPath}" ];then
  _log "Single file torrent, nothing to do"
  exit
elif [ -n $( _find_rars "${torrentPath}" ) ];then
  _log "Torrent with rar files, unpacking"
  _unrar_torrent ${torrentPath} .
else
  _log "No rar files found"
fi
EOF
sudo chmod +x /home/vpn/unpack.sh
sudo chown vpn: /home/vpn/unpack.sh
systemctl enable transmission-daemon
##switch to python3 and pip3 and make them default
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 10
sudo update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1
##install nodejs and cloudcmd with gritty  for web file and ssh##
sudo apt-get install -y nodejs
sudo -H -E npm config set user 0
sudo -H -E npm config set unsafe-perm true
sudo -H -E npm install cloudcmd -g
sudo -H -E npm install gritty -g
sudo -H -E npm install fsevents@latest -g -f
##using PM2 to control npm programs on startup and reboot
sudo -H -E npm install pm2@latest -g
##Start Cloudcmd Temp for gritty access @ port 8000##
## commented out next line as I cant get gritty to work inside cloudcmd any longer 
#tmux new-session -d -s "cloudtmp" cloudcmd --terminal --terminal-path `gritty --path` --save
#sleep 3
#tmux kill-session -t cloudtmp
## Better Youtube DL
wget https://github.com/Tzahi12345/YoutubeDL-Material/releases/download/v4.1/youtubedl-material-4.1.zip
unzip youtubedl-material-4.1.zip -d /tmp/
mv /tmp/youtubedl-material/ /home/media/youtubedl
chown media:media /home/media/youtubedl -Rv
rm /tmp/youtubedl-material-4.1.zip
cd /home/media/youtubedl
sudo -u media npm -- install /home/media/youtubedl/
sudo -u media npm --prefix /home/media/youtubedl/ uuid@latest
sudo -u media npm --prefix /home/media/youtubedl/ fsevents@latest
sudo -u media pm2 start npm -- start ~youtubedl/
sudo -u media pm2 save
sudo -u media pm2 startup
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u media --hp /home/media
pm2 start cloudcmd
pm2 save
pm2 startup
## not adding gritty to starpm2 start grittytup for security reason, running on install script on default port 
pm2 start gritty
##you can now login to cloudcmd @ server ip port:8000
##fix permission on ssh and transmisson for root acces ** security issue ** set back after setup complete##
sed -i '/PermitRootLogin/c PermitRootLogin yes' /etc/ssh/sshd_config ;
sed -i '/blacklist snd_pcsp/c #blacklist snd_pcsp' /etc/modprobe.d/blacklist.conf ;
sed -i '/blacklist pcspkr/c #blacklist pcspkr' /etc/modprobe.d/blacklist.conf ;
##restore ubuntu pc speaker for up down beeps, this is a ubuntu thing not required on debian ##
modprobe pcspkr
sed -i '/;cgi.fix_pathinfo=1/c cgi.fix_pathinfo=0' /etc/php/7.4/fpm/php.ini;
##install the scripts that make things work better together ##
cd /opt
git clone https://github.com/mdhiggins/sickbeard_mp4_automator.git mp4auto
git clone https://github.com/begleysm/ipwatch.git
git clone https://github.com/mrworf/plexupdate.git
##setup newer sonarr with user media without asking##
cat > /opt/sonarr.seed <<SON
sonarr sonarr/owning_user string media
sonarr sonarr/config_directory string /var/lib/sonarr
sonarr sonarr/owning_group string media
SON
sudo debconf-set-selections /opt/sonarr.seed
apt install sonarr plexmediaserver -y
rm sonarr.seed
## startup and shutdown sound if headless server is in residence you can hear it complete boot process 
echo "[Unit]
        Description=Beep after system start
        DefaultDependencies=no
        After=multi-user.target
        [Service]
        Type=oneshot
        ExecStart=/usr/bin/beep -f 3000 -l 100 -n -f 3500 -l 100 -r 2
        [Install]
        WantedBy=multi-user.target
  " > /lib/systemd/system/systemup.service;
echo "[Unit]
        Description=Beep before system shutdown
        DefaultDependencies=no
        Before=exit.target
        [Service]
        Type=oneshot
        ExecStart=/usr/bin/beep -f 3000 -l 100 -r 2 -n -f 2000 -l 150
        [Install]
        WantedBy=reboot.target halt.target poweroff.target
" > /lib/systemd/system/systemdown.service;
systemctl enable systemup;
systemctl start systemup;
systemctl enable systemdown;
systemctl start systemdown;
cd /opt;
wget https://raw.githubusercontent.com/Pupwiz/server/master/deb/index.php
wget https://raw.githubusercontent.com/Pupwiz/server/master/deb/default
mv /opt/default /etc/nginx/sites-available/ -v
##V3 Radarr install 
sudo curl -SL "https://radarr.servarr.com/v1/update/nightly/updatefile?os=linux&runtime=netcore&arch=x64" -o radarr.tar.gz
sudo tar xvf /opt/radarr.tar.gz
sudo rm /opt/radarr.tar.gz
sudo chown media:media /opt/Radarr -Rv;
echo "[Unit]
Description=Radarr Daemon
After=syslog.target network.target
  [Service]
User=media
Type=simple
ExecStart=/opt/Radarr/Radarr
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
" > /lib/systemd/system/radarr.service;
systemctl enable radarr.service;
systemctl start radarr.service;
#setup MP4 automator to work with Radarr and Sonarr install all requirements##
chown media:media /opt/mp4auto -Rv;
pip install -r /opt/mp4auto/setup/requirements.txt
cp /opt/mp4auto/setup/autoProcess.ini.sample /opt/mp4auto/config/autoProcess.ini
sed -i '/temp-extension/c temp-extension = conv' /opt/mp4auto/config/autoProcess.ini
sed -i '/temp-extension/c temp-extension = conv' /opt/mp4auto/config/autoProcess.ini
sed -i '/ffmpeg = ffmpeg.exe/c ffmpeg = ffmpeg' /opt/mp4auto/config/autoProcess.ini
sed -i '/ffmpeg = ffprobe.exe/c ffmpeg = ffprobe' /opt/mp4auto/config/autoProcess.ini
wget https://nzbget.net/download/nzbget-latest-bin-linux.run
chmod +x nzbget-latest-bin-linux.run
./nzbget-latest-bin-linux.run
chown media:media /opt/nzbget -Rv;
echo "[Unit]
Description=NZBGet Daemon
After=network.target
[Service]
Type=forking
User=media
ExecStart=/opt/nzbget/nzbget -c /opt/nzbget/nzbget.conf -D
ExecStop=/opt/nzbget/nzbget -Q
ExecReload=/opt/nzbget/nzbget -O
KillMode=process
[Install]
WantedBy=multi-user.target
" > /lib/systemd/system/nzbget.service;
systemctl enable nzbget;
systemctl start nzbget;
rm nzbget-latest-bin-linux.run
jackett=$(curl -s https://api.github.com/repos/Jackett/Jackett/releases/latest | grep AMDx64 | grep browser_download_url | cut -d \" -f4)
wget -q $jackett
tar -xvzf Jackett.Binaries.LinuxAMDx64.tar.gz       
	chown -R media:media /opt/Jackett;
	echo "[Unit]
        Description=Jackett Daemon
	After=network.target
	[Service]
	WorkingDirectory=/opt/Jackett/
	User=media
	ExecStart=/opt/Jackett/jackett
	Restart=always
	RestartSec=2
	Type=simple
	TimeoutStopSec=5
        [Install]
        WantedBy=multi-user.target
	" > /lib/systemd/system/jackett.service;
        systemctl enable jackett;
        systemctl start jackett;
        rm Jackett.Binaries.LinuxAMDx64*;
##update youtubedl for Plex Videos
sudo curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl
sudo chmod a+rx /usr/local/bin/youtube-dl
pip install flask 
pip install apt-select
## apt-select usage example apt-select --country CA -t 3
#git clone https://github.com/d0u9/youtube-dl-webui.git
#cd /opt/youtube-dl-webui
#chmod 777 setup.py
#python setup.py install
#cat > /opt/ytdl.config.json <<EOF
#{
#    "general": {
#        "download_dir": "/home/media/youtube",
#        "db_path": "/home/media/youtube_dl_webui.db",
#        "log_size": 10
#    },
#    "youtube_dl": {
#        "format": "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
#    },
#    "server": {
#        "host": "0.0.0.0",
#        "port": "5000"
#    }
#}
#EOF
#cat > /lib/systemd/system/ytdl.service <<EOF
#[Unit]
#Description=Youtube-dl Gui
#
#[Service]
#Type=forking
#ExecStart=/usr/bin/tmux new-session -d -s youtubedl 'youtube-dl-webui -c /opt/ytdl.config.json'
#
#
#[Install]
#WantedBy=default.target
#EOF
#systemctl enable ytdl.service
##remove sql nasty password block / set to none##
/etc/init.d/mysql stop
killall mysqld_safe
killall mysqld
sleep 3
mysqld_safe --skip-grant-tables &
echo "USE mysql;">/tmp/mariadbsolve.sql
echo 'UPDATE `user` SET `plugin`="" Where `User`="root";'>>/tmp/mariadbsolve.sql
echo "FLUSH PRIVILEGES;">>/tmp/mariadbsolve.sql
echo "exit">>/tmp/mariadbsolve.sql
sleep 2
mysql -u root < /tmp/mariadbsolve.sql
sleep 2
/etc/init.d/mysql stop
sleep 2
killall mysqld_safe
killall mysqld
cd /tmp
##Allow samba to talk to windows 10 without ip's##
wget https://github.com/christgau/wsdd/archive/master.zip
unzip master.zip
sudo mv wsdd-master/src/wsdd.py wsdd-master/src/wsdd
sudo cp wsdd-master/src/wsdd /usr/bin
echo "[Unit]
Description=Web Services Dynamic Discovery host daemon
; Start after the network has been configured
After=network-online.target
Wants=network-online.target
; It makes sense to have Samba running when wsdd starts, but is not required
Wants=smb.service

[Service]
Type=simple
ExecStart=/usr/bin/wsdd --shortlog
; Replace those with an unprivledged user/group that matches your environment,
; like nobody/nogroup or daemon:daemon or a dedicated user for wsdd
; User=nobody 
; Group=nobody
; The following lines can be used for a chroot execution of wsdd.
; Also append '--chroot /run/wsdd/chroot' to ExecStart to enable chrooting
;AmbientCapabilities=CAP_SYS_CHROOT
;ExecStartPre=/usr/bin/install -d -o nobody -g nobody -m 0700 /run/wsdd/chroot
;ExecStopPost=rmdir /run/wsdd/chroot

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/wsdd.service
sudo systemctl enable wsdd
sudo systemctl start wsdd
##install browsh for ssh firefox access may have to move .Xautority from media to root##
wget https://github.com/browsh-org/browsh/releases/download/v1.6.4/browsh_1.6.4_linux_amd64.deb
sudo apt install -y ./browsh_1.6.4_linux_amd64.deb
rm ./browsh_1.6.4_linux_amd64.deb
cd /var/www/html
wget https://newcontinuum.dl.sourceforge.net/project/mywebsql/stable/mywebsql-3.7.zip
unzip mywebsql-3.7.zip -d /var/www/html
chown -R www-data:www-data /var/www/html/mywebsql/
chmod -R 775 /var/www/html/mywebsql/
mv /opt/default /etc/nginx/sites-available/ -v
mv /opt/index.php /var/www/html/ -v
mv /opt/.htpasswd /etc/nginx/ -v
chmod +x /home/media/unpack.sh 
##house keeping##
##verbose grub booting for info its a server??##
sed -i '/GRUB_TIMEOUT_STYLE=hidden/d' /etc/default/grub;
sed -i '/splash quiet/d' /etc/default/grub;
sed -i '/GRUB_TIMEOUT=0/c GRUB_TIMEOUT=2' /etc/default/grub;
sed -i '$ a GRUB_RECORDFAIL_TIMEOUT=0' /etc/default/grub;
sudo update-grub
apt update
apt upgrade -y
apt autoremove -y
sudo init 6
