apt purge apparmour cloud-init snapd -y
usermod -aG sudo media
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
sysctl -p
curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add -;
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
wget -nv https://downloads.plex.tv/plex-keys/PlexSign.key -O- | apt-key add -;
echo "deb https://downloads.plex.tv/repo/deb public main" | tee  /etc/apt/sources.list.d/plexserver.list;
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0C54D189F4BA284D;
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4f4ea0aae5267a6c
sudo add-apt-repository ppa:ondrej/php -y
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8
echo "deb https://apt.sonarr.tv/ubuntu focal main" | sudo tee /etc/apt/sources.list.d/sonarr.list
apt update
##uncomment next lines if you want virtual machine installed
#apt install -y qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager
#adduser media libvirt
#adduser media libvirt-qemu
##Things needed to make it all work together
apt install -y beep genisoimage libarchive-tools syslinux-utils wget sharutils sudo gnupg ca-certificates curl git dirmngr apt-transport-https unzip zip unrar ffmpeg mono-devel transmission-daemon debconf-utils
##Istalling Nginx and PHP for simple webpage also included mysql plugins
apt install -q -y  nginx php7.4 php7.4-common php7.4-cli php7.4-fpm python3-pip openvpn --allow-unauthenticated;
apt install -y -q php7.4-mysql php7.4-gd php7.4-json php7.4-curl php7.4-zip php7.4-xml php7.4-mbstring php7.4-pgsql php7.4-bcmath;
#apt install -y -q mariadb-server ##if you need it
apt install -y -q python-dev python-lxml libxml2-dev libffi-dev libssl-dev libjpeg-dev libpng-dev uuid-dev python-dbus;
apt install -q -y sqlite3 htop mediainfo samba cifs-utils smbclient dos2unix avahi-daemon avahi-discover avahi-utils libnss-mdns mdns-scan;
systemctl stop transmission-daemon
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
sudo -H -E npm install pm2@latest -g
##Start Cloudcmd Temp for gritty access @ port 8000##
tmux new-session -d -s "cloudtmp" cloudcmd --terminal --terminal-path `gritty --path` --save
sleep 3
tmux kill-session -t cloudtmp
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
##you can now login to cloudcmd @ server ip port:8000
##next fix permission on ssh and transmisson for access##
sed -i '/PermitRootLogin/c PermitRootLogin yes' /etc/ssh/sshd_config ;
sed -i '/blacklist snd_pcsp/c #blacklist snd_pcsp' /etc/modprobe.d/blacklist.conf ;
sed -i '/blacklist pcspkr/c #blacklist pcspkr' /etc/modprobe.d/blacklist.conf ;
sed -i '/"rpc-authentication-required": *true/ s/true/false/' /etc/transmission-daemon/settings.json
sed -i '/"rpc-host-whitelist-enabled": *true/ s/true/false/'  /etc/transmission-daemon/settings.json
sed -i '/"rpc-whitelist-enabled": *true/ s/true/false/'  /etc/transmission-daemon/settings.json
systemctl enable transmission-daemon
##restore ubuntu pc speaker for up down beeps##
modprobe pcspkr
sed -i '/;cgi.fix_pathinfo=1/c cgi.fix_pathinfo=0' /etc/php/7.4/fpm/php.ini;
##install the cool accessories that make things work better##
cd /opt
git clone https://github.com/mdhiggins/sickbeard_mp4_automator.git mp4auto
git clone https://github.com/begleysm/ipwatch.git
git clone https://github.com/mrworf/plexupdate.git
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8
echo "deb https://apt.sonarr.tv/ubuntu focal main" | sudo tee /etc/apt/sources.list.d/sonarr.list
sudo apt update
##setup newer sonarr with user media without asking##
cat > /opt/sonarr.seed <<SON
sonarr sonarr/owning_user string media
sonarr sonarr/config_directory string /var/lib/sonarr
sonarr sonarr/owning_group string media
SON
sudo debconf-set-selections /opt/sonarr.seed
apt install sonarr plexmediaserver -y
rm sonarr.seed
##use google downloader to get new version of Radarr##
#wget https://raw.githubusercontent.com/circulosmeos/gdown.pl/master/gdown.pl
#chmod +x gdown.pl
echo "[Unit]
        Description=Cloud Commander
        [Service]
        TimeoutStartSec=0
        Restart=always
        User=root
        WorkingDirectory=/home/media
        ExecStart=/usr/bin/cloudcmd
        [Install]
        WantedBy=multi-user.target
        " > /lib/systemd/system/cloudcmd.service;
        systemctl enable cloudcmd.service;
        systemctl start cloudcmd.service;
        systemctl enable plexmediaserver.service;
        systemctl start plexmediaserver;
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
wget https://raw.githubusercontent.com/Pupwiz/server/master/deb/unpack.sh
mv /opt/default /etc/nginx/sites-available/ -v
#./gdown.pl https://drive.google.com/file/d/1AwnCW__YiQ__qAed9saAsZpCY_Nrn0Fd/view?usp=sharing
#rm gdown.pl
#mv gdown.* radarr.tar.gz
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
git clone https://github.com/d0u9/youtube-dl-webui.git
cd /opt/youtube-dl-webui
chmod 777 setup.py
python setup.py install
cat > /opt/ytdl.config.json <<EOF
{
    "general": {
        "download_dir": "/home/media/youtube",
        "db_path": "/home/media/youtube_dl_webui.db",
        "log_size": 10
    },
    "youtube_dl": {
        "format": "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
    },
    "server": {
        "host": "0.0.0.0",
        "port": "5000"
    }
}
EOF
cat > /lib/systemd/system/ytdl.service <<EOF
[Unit]
Description=Youtube-dl Gui

[Service]
Type=forking
ExecStart=/usr/bin/tmux new-session -d -s youtubedl 'youtube-dl-webui -c /opt/ytdl.config.json'

[Install]
WantedBy=default.target
EOF
systemctl enable ytdl.service
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
mv /opt/unpack.sh /home/media/ -v
##house keeping##
##verbose grub booting for info its a server??##
sed -i '/GRUB_TIMEOUT_STYLE=hidden/d' /etc/default/grub;
sed -i '/splash quiet/d' /etc/default/grub;
sed -i '/GRUB_TIMEOUT=0/c GRUB_TIMEOUT=3' /etc/default/grub;
sed -i '$ a GRUB_RECORDFAIL_TIMEOUT=0' /etc/default/grub;
update-grub2
