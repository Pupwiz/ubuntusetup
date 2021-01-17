sudo apt install -y lsb-release apt-transport-https dnsutils ca-certificates software-properties-common tmux curl wget
curl -sL https://deb.nodesource.com/setup_15.x | sudo -E bash -
##install nodejs and cloudcmd with gritty  for web file and ssh##
sudo apt-get install -y nodejs
sudo -H -E npm config set user 0
sudo -H -E npm config set unsafe-perm true
sudo -H -E npm install cloudcmd -g
sudo -H -E npm install gritty -g
tmux new-session -d -s "cloudtmp" cloudcmd --terminal --terminal-path `gritty --path` --save
sleep 3
tmux kill-session -t cloudtmp
cat <<'EOF'>/etc/systemd/system/cloudcmd.service
[Unit]
        Description=Cloud Commander
        [Service]
        TimeoutStartSec=0
        Restart=always
        User=root
        WorkingDirectory=/home/media
        ExecStart=/usr/bin/cloudcmd
        [Install]
        WantedBy=multi-user.target
EOF
systemctl enable cloudcmd.service
systemctl start cloudcmd.service 
wget https://raw.githubusercontent.com/Pupwiz/ubuntusetup/main/nginx_build.sh
chmod +x ./nginx_build

