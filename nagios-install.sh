#!/bin/bash


sudo apt-get update
sudo apt-get -y install apache2 libapache2-mod-php5 build-essential libgd2-xpm-dev subversion git-core xinetd rrdtool librrds-perl

cd /usr/local/src
sudo wget -nc http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-4.0.2.tar.gz
sudo wget -nc http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-3.5.1.tar.gz
#wget -nc http://sourceforge.net/projects/nagiosgraph/files/nagiosgraph/1.4.4/nagiosgraph-1.4.4.tar.gz
sudo tar xzf nagios-3.4.0.tar.gz
sudo tar xzf nagios-plugins-1.4.15.tar.gz
#tar xzf nagiosgraph-1.4.4.tar.gz

sudo useradd -m -s /bin/bash nagios
echo 'Enter the password for the new user nagios'
sudo passwd nagios
sudo groupadd nagcmd
sudo usermod -a -G nagcmd nagios
sudo usermod -a -G nagcmd www-data

cd cd nagios-4.0.2
sudo ./configure --with-command-group=nagcmd
sudo make all
sudo make install
sudo make install-init
sudo make install-config
sudo make install-commandmode
sudo make install-webconf
echo 'Enter the password for the user nagiosadmin'
sudo htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin
sudo service apache2 reload

cd cd ../nagios-3.5.1
sudo ./configure --with-nagios-user=nagios --with-nagios-group=nagios
sudo make
sudo make install

# install PyNag
sudo apt-get install pynag

# install Mconf stuff
sudo apt-get -y install python-argparse
sudo mkdir tools
cd tools
git clone https://github.com/canhlinh/nagios-etc.git
sudo cp -r tools/nagios-etc/libexec/nagios-hosts/ /usr/local/nagios/libexec/
sudo cp -r tools/nagios-etc/libexec/emeeting/ /usr/local/nagios/libexec/
sudo cp -r tools/nagios-etc/etc/objects/emeeting/ /usr/local/nagios/etc/objects/
sudo cp /usr/local/nagios/etc/nagios.cfg /usr/local/nagios/etc/nagios.cfg.original
# done on bbb-deploy/install-monitor.sh
# sudo cp /usr/local/nagios/etc/nsca.cfg /usr/local/nagios/etc/nsca.cfg.backup
sudo cp tools/nagios-etc/etc/nagios.cfg tools/nagios-etc/etc/nsca.cfg /usr/local/nagios/etc/

sudo crontab -l | grep -v "nagios-hosts.py" > cron.jobs
echo "*/1 * * * * /usr/bin/python /usr/local/nagios/libexec/nagios-hosts/nagios-hosts.py reload" >> cron.jobs
sudo crontab cron.jobs
rm cron.jobs

# configuring the central server
sudo sed -i "s:nagios@localhost:mconf.prav@gmail.com:g" /usr/local/nagios/etc/objects/contacts.cfg
sudo sed -i "s:.*enable_notifications=.*:enable_notifications=1:g" /usr/local/nagios/etc/nagios.cfg
sudo sed -i "s:.*execute_service_checks=.*:execute_service_checks=1:g" /usr/local/nagios/etc/nagios.cfg
sudo sed -i "s:.*check_external_commands=.*:check_external_commands=1:g" /usr/local/nagios/etc/nagios.cfg
sudo sed -i "s:.*accept_passive_service_checks=.*:accept_passive_service_checks=1:g" /usr/local/nagios/etc/nagios.cfg

# configuring status-json

sudo ln -s /etc/init.d/nagios /etc/rcS.d/S99nagios
sudo mkdir -p /usr/local/nagios/var/spool/checkresults
sudo mkdir -p /usr/local/nagios/var/archives
sudo chown -R nagios:nagios /usr/local/nagios

sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
sudo service nagios start