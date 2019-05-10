#!/bin/bash
#
# https://github.com/hiandras/rspamd_installer
#
# Installer for rspamd
# More info: https://rspamd.com/
#
# Copyright (c) 2019 hiandras Released under GNU GPLv3 license

clear
echo "Installer for rspamd"
echo
echo "The following modules will be installed:"
echo
echo "- basic linux tools"
echo "- rspamd required modules (unbound, redis-server, clamav)"
echo "- apache2 web server"
echo "- postfix mail server (optional)"
echo "- shorewall firewall (optional)"
echo "- letsencrypt certificate (optional)"
echo "- webmin (optional)"
echo "- munin (optional)"

echo
echo "1. step:"
echo "Install basic linux tools"
echo
read -p "Press enter to continue"
apt-get update
apt-get install net-tools --assume-yes
apt-get install dnsutils --assume-yes
echo "NTP=0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org" >> /etc/systemd/timesyncd.conf
echo "FallbackNTP=0.debian.pool.ntp.org 1.debian.pool.ntp.org 2.debian.pool.ntp.org 3.debian.pool.ntp.org"  >> /etc/systemd/timesyncd.conf
apt-get install dbus --assume-yes
timedatectl set-ntp true

echo
echo "2. step:"
echo "Install required modules (unbound, redis-server, clamav)"
echo
read -p "Press enter to continue"
apt-get install unbound --assume-yes
su -c "unbound-anchor -a /var/lib/unbound/root.key" - unbound
systemctl reload unbound
apt-get install redis-server --assume-yes
apt-get install clamav --assume-yes

echo
echo "3. step:"
echo "Install apache2 and configure it"
echo
read -p "Press enter to continue"
apt-get install apache2 --assume-yes
a2enmod proxy
a2enmod proxy_http
echo "ProxyPreserveHost On" >> /etc/apache2/conf-available/rspamd.conf
echo "ProxyPass /rspamd http://localhost:11334/" >> /etc/apache2/conf-available/rspamd.conf
echo "ProxyPassReverse /rspamd http://localhost:11334/" >> /etc/apache2/conf-available/rspamd.conf
a2enconf rspamd
service apache2 restart
echo "<!DOCTYPE html>" > /var/www/html/index.html
echo "<html>" >> /var/www/html/index.html
echo "<head>" >> /var/www/html/index.html
echo "<title>Rspamd</title>" >> /var/www/html/index.html
echo '<meta http-equiv="refresh" content="0; url=/rspamd/" />' >> /var/www/html/index.html
echo "</head>" >> /var/www/html/index.html
echo "<body>" >> /var/www/html/index.html
echo "</body>" >> /var/www/html/index.html
echo "</html>" >> /var/www/html/index.html

echo
echo "4. step:"
echo "Install rspamd itself and run configwizard"
echo
read -p "Press enter to continue"
wget -O- https://rspamd.com/apt-stable/gpg.key | apt-key add -
echo "deb http://rspamd.com/apt-stable/ $(lsb_release -c -s) main" > /etc/apt/sources.list.d/rspamd.list
echo "deb-src [arch=amd64] http://rspamd.com/apt-stable/ $(lsb_release -c -s) main" >> /etc/apt/sources.list.d/rspamd.list
apt-get update
apt-get --no-install-recommends install rspamd --assume-yes
rspamadm configwizard

echo
echo "5. step:"
echo "Add additional components (anitvirus, whitelist, blacklist, historyredis, etc)"
echo
read -p "Press enter to continue"
echo "clamav {servers = \"127.0.0.1:3310\";}" > /etc/rspamd/local.d/antivirus.conf
echo "backend = \"redis\";" > /etc/rspamd/local.d/classifier-bayes.conf
echo "nrows = 20000; # Default rows limit"> /etc/rspamd/local.d/history_redis.conf
echo "local_addrs = \"127.0.0.0/8, ::1\";" > /etc/rspamd/local.d/options.inc
echo "dns {nameserver = [\"127.0.0.1:53:10\"];}" >> /etc/rspamd/local.d/options.inc
echo "servers = \"127.0.0.1\";" > /etc/rspamd/local.d/redis.conf
echo "bind_socket = \"localhost:11333\";" > /etc/rspamd/local.d/worker-normal.inc
echo "milter = yes; # Enable milter mode" > /etc/rspamd/local.d/worker-proxy.inc
echo "timeout = 120s; # Needed for Milter usually" >> /etc/rspamd/local.d/worker-proxy.inc
echo "upstream \"local\" {" >> /etc/rspamd/local.d/worker-proxy.inc
echo "  default = yes; # Self-scan upstreams are always default" >> /etc/rspamd/local.d/worker-proxy.inc
echo "  self_scan = yes; # Enable self-scan" >> /etc/rspamd/local.d/worker-proxy.inc
echo "}" >> /etc/rspamd/local.d/worker-proxy.inc
echo "count = 4; # Spawn more processes in self-scan mode" >> /etc/rspamd/local.d/worker-proxy.inc
echo "max_retries = 5; # How many times master is queried in case of failure" >> /etc/rspamd/local.d/worker-proxy.inc
echo "discard_on_reject = false; # Discard message instead of rejection" >> /etc/rspamd/local.d/worker-proxy.inc
echo "quarantine_on_reject = false; # Tell MTA to quarantine rejected messages" >> /etc/rspamd/local.d/worker-proxy.inc
echo "spam_header = \"X-Spam\"; # Use the specific spam header" >> /etc/rspamd/local.d/worker-proxy.inc
echo "reject_message = \"Spam message rejected\"; # Use custom rejection message" >> /etc/rspamd/local.d/worker-proxy.inc
echo "use = [\"x-spamd-bar\", \"x-spam-level\", \"authentication-results\"];" >> /etc/rspamd/local.d/milter_headers.conf
echo "authenticated_headers = [\"authentication-results\"];" >> /etc/rspamd/local.d/milter_headers.conf
touch /etc/rspamd/local.d/local_bl_from.map.inc
chmod o+w /etc/rspamd/local.d/local_bl_from.map.inc
touch /etc/rspamd/local.d/local_bl_mailfrom.map.inc
chmod o+w /etc/rspamd/local.d/local_bl_mailfrom.map.inc
touch /etc/rspamd/local.d/local_wl_ip.map.inc
chmod o+w /etc/rspamd/local.d/local_wl_ip.map.inc
touch /etc/rspamd/local.d/local_wl_from.map.inc
chmod o+w /etc/rspamd/local.d/local_wl_from.map.inc
echo "# Blacklists" > /etc/rspamd/local.d/multimap.conf
echo "local_bl_mailfrom { type = \"from\"; map = \"\$LOCAL_CONFDIR/local.d/local_bl_mailfrom.map.inc\"; symbol = \"LOCAL_BL_MAILFROM\"; description = \"Local MAILFROM blacklist\";score = 99;}" >> /etc/rspamd/local.d/multimap.conf
echo "local_bl_from { type = \"header\"; header=\"from\";  map = \"\$LOCAL_CONFDIR/local.d/local_bl_from.map.inc\"; symbol = \"LOCAL_BL_FROM\"; description = \"Local FROM blacklist\";score = 99;}" >> /etc/rspamd/local.d/multimap.conf
echo "# Whitelists" >> /etc/rspamd/local.d/multimap.conf
echo "local_wl_ip { type = \"ip\"; map = \"\$LOCAL_CONFDIR/local.d/local_wl_ip.map.inc\"; symbol = \"LOCAL_WL_IP\"; description = \"Local IP whitelist\";score = -99;}" >> /etc/rspamd/local.d/multimap.conf
echo "local_wl_from { type = \"from\"; map = \"\$LOCAL_CONFDIR/local.d/local_wl_from.map.inc\"; symbol = \"LOCAL_WL_FROM\"; description = \"Local FROM whitelist\";score = -99;}" >> /etc/rspamd/local.d/multimap.conf
echo "enabled = true;" > /etc/rspamd/local.d/mx_check.conf

echo
echo "6. step: Install postfix"
echo
read -p "Do you want to install Postifx? [Y/n]: " -e POSTFIX
if [[ "$POSTFIX" = 'y' || "$POSTFIX" = 'Y' || "$POSTFIX" = '' ]]; then
echo "You shoud choose \"Internet Site\" and enter FQDN name during installation"
echo
read -p "Press enter to continue"
apt-get install postfix --assume-yes
echo >> /etc/postfix/main.cf
sed -i "s/defer_unauth_destination/reject_unauth_destination/" /etc/postfix/main.cf
echo "# Relay domains" >> /etc/postfix/main.cf
echo "relay_domains = hash:/etc/postfix/transport" >> /etc/postfix/main.cf
echo "transport_maps = hash:/etc/postfix/transport" >> /etc/postfix/main.cf
echo "# /etc/postfix/transport" >> /etc/postfix/transport
echo "# run 'postmap /etc/postfix/transport' after each edit" >> /etc/postfix/transport
echo >> /etc/postfix/transport
echo "example.com    smtp:mail.example.com:25" >> /etc/postfix/transport
echo >> /etc/postfix/main.cf
echo "# Increase max message size" >> /etc/postfix/main.cf
echo "message_size_limit = 40960000" >> /etc/postfix/main.cf
echo >> /etc/postfix/main.cf
echo "# Reject unwanted emails at postfix" >> /etc/postfix/main.cf
echo "smtpd_sender_restrictions = reject_unknown_sender_domain" >> /etc/postfix/main.cf
echo "smtpd_recipient_restrictions = reject_unverified_recipient" >> /etc/postfix/main.cf
echo "unverified_recipient_reject_code = 550" >> /etc/postfix/main.cf
echo >> /etc/postfix/main.cf
echo "# Required for rspamd" >> /etc/postfix/main.cf
echo "smtpd_milters = inet:localhost:11332" >> /etc/postfix/main.cf
echo "non_smtpd_milters = inet:localhost:11332" >> /etc/postfix/main.cf
echo "milter_default_action = accept" >> /etc/postfix/main.cf
postmap /etc/postfix/transport
service postfix restart
fi

echo
echo "7. step: Install Shorewall"
echo
read -p "Do you want to install Shorewall? [Y/n]: " -e SHOREWALL
if [[ "$SHOREWALL" = 'y' || "$SHOREWALL" = 'Y' || "$SHOREWALL" = '' ]]; then
apt-get install shorewall --assume-yes
mkdir /etc/shorewall/zones
cp /usr/share/doc/shorewall/examples/one-interface/interfaces /etc/shorewall
cp /usr/share/doc/shorewall/examples/one-interface/policy /etc/shorewall
cp /usr/share/doc/shorewall/examples/one-interface/rules /etc/shorewall
cp /usr/share/doc/shorewall/examples/one-interface/zones /etc/shorewall
echo "ACCEPT\tnet\tfw\ttcp\t22" >>/etc/shorewall/rules
echo "ACCEPT\tnet\tfw\ttcp\t25" >>/etc/shorewall/rules
echo "ACCEPT\tnet\tfw\ttcp\t80" >>/etc/shorewall/rules
echo "ACCEPT\tnet\tfw\ttcp\t443" >>/etc/shorewall/rules
echo "ACCEPT\tnet\tfw\ttcp\t4949" >>/etc/shorewall/rules
echo "ACCEPT\tnet\tfw\ttcp\t10000" >>/etc/shorewall/rules
echo "ACCEPT\tnet\tfw\ticmp" >>/etc/shorewall/rules
sed -i 's/Ping(DROP)/#Ping(DROP)/' /etc/shorewall/rules
service shorewall start
fi

echo
echo "8. step: Install webmin"
echo
read -p "Do you want to install webmin? [Y/n]: " -e WEBMIN
if [[ "$WEBMIN" = 'y' || "$WEBMIN" = 'Y' || "$WEBMIN" = '' ]]; then
echo "deb https://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list
cd /root
wget http://www.webmin.com/jcameron-key.asc
apt-key add jcameron-key.asc
apt-get install apt-transport-https --assume-yes
apt-get update
apt-get install webmin --assume-yes
fi

echo
echo "9. step: Install munin"
echo
read -p "Do you want to install munin? [Y/n]: " -e MUNIN
if [[ "$MUNIN" = 'y' || "$MUNIN" = 'Y' || "$MUNIN" = '' ]]; then
apt-get install munin munin-node munin-plugins-extra --assume-yes
sed -i -e '0,/local/ s/local/all granted/' /etc/munin/apache24.conf
sed -i 's/None/FollowSymLinks SymLinksIfOwnerMatch/' /etc/munin/apache24.conf
service apache2 restart
fi

echo
echo "10. step: Install letsencrypt"
echo
read -p "Do you want to install Letsencrypt? [Y/n]: " -e LETSENCRYPT
if [[ "$LETSENCRYPT" = 'y' || "$LETSENCRYPT" = 'Y' || "$LETSENCRYPT" = '' ]]; then
apt-get update
apt-get install dehydrated --assume-yes
apt-get install dehydrated-apache2 --assume-yes
clear
read -p "Domain name for certificate? " -e FQDN
echo $FQDN > /etc/dehydrated/domains.txt
/usr/bin/dehydrated --cron
echo "10 23 * * *   root    /usr/bin/dehydrated --cron > /dev/null 2>&1" >>/etc/crontab
echo "20 23 * * *   root    service postfix reload > /dev/null 2>&1" >>/etc/crontab
echo "22 23 * * *   root    service webmin restart > /dev/null 2>&1" >>/etc/crontab
echo "24 23 * * *   root    service apache2 reload > /dev/null 2>&1" >>/etc/crontab
sed -i "s/=\/etc\/ssl\/certs\/ssl-cert-snakeoil.pem/=\/var\/lib\/dehydrated\/certs\/${FQDN}\/fullchain.pem/" /etc/postfix/main.cf
sed -i "s/=\/etc\/ssl\/private\/ssl-cert-snakeoil.key/=\/var\/lib\/dehydrated\/certs\/${FQDN}\/privkey.pem/" /etc/postfix/main.cf
service postfix reload
sed -i "s/=\/etc\/webmin\/miniserv.pem/=\/var\/lib\/dehydrated\/certs\/${FQDN}\/privkey.pem/" /etc/webmin/miniserv.conf
echo "certfile=/var/lib/dehydrated/certs/${FQDN}/cert.pem" >> /etc/webmin/miniserv.conf
echo "extracas=/var/lib/dehydrated/certs/${FQDN}/chain.pem" >> /etc/webmin/miniserv.conf
service webmin restart
echo "<VirtualHost *:80>" >/etc/apache2/sites-available/$FQDN.conf
echo "ServerName ${FQDN}" >>/etc/apache2/sites-available/$FQDN.conf
echo "RedirectPermanent / https://${FQDN}/" >>/etc/apache2/sites-available/$FQDN.conf
echo "</VirtualHost>" >>/etc/apache2/sites-available/$FQDN.conf
echo "" >>/etc/apache2/sites-available/$FQDN.conf
echo "<VirtualHost *:443>" >>/etc/apache2/sites-available/$FQDN.conf
echo "ServerAdmin webmaster@localhost" >>/etc/apache2/sites-available/$FQDN.conf
echo "DocumentRoot /var/www/html" >>/etc/apache2/sites-available/$FQDN.conf
echo "ServerName ${FQDN}" >>/etc/apache2/sites-available/$FQDN.conf
echo "ErrorLog \${APACHE_LOG_DIR}/error.log" >>/etc/apache2/sites-available/$FQDN.conf
echo "CustomLog \${APACHE_LOG_DIR}/access.log combined" >>/etc/apache2/sites-available/$FQDN.conf
echo "SSLEngine on" >>/etc/apache2/sites-available/$FQDN.conf
echo "SSLProtocol ALL -SSLv2 -SSLv3" >>/etc/apache2/sites-available/$FQDN.conf
echo "SSLHonorCipherOrder on" >>/etc/apache2/sites-available/$FQDN.conf
echo "SSLCipherSuite ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL" >>/etc/apache2/sites-available/$FQDN.conf
echo "SSLCertificateFile /var/lib/dehydrated/certs/${FQDN}/fullchain.pem" >>/etc/apache2/sites-available/$FQDN.conf
echo "SSLCertificateKeyFile /var/lib/dehydrated/certs/${FQDN}/privkey.pem" >>/etc/apache2/sites-available/$FQDN.conf
echo "</VirtualHost>" >>/etc/apache2/sites-available/$FQDN.conf
a2enmod ssl
a2ensite $FQDN
service apache2 reload
sed -i "s/\/rspamd\//https:\/\/${FQDN}\/rspamd\//" /var/www/html/index.html
fi

if [ "$FQDN" = '' ]; then
FQDN="$(hostname -I)"
fi

echo
echo "DONE"
echo
echo "Usage:"
echo
echo "Rspamd webgui: https://${FQDN}/rspamd/"
echo
echo "Webmin: https://${FQDN}:10000"
echo
echo "Munin: https://${FQDN}/munin/"
echo
echo "Now, add your own domain names to postfix's /etc/postfix/transport file,"
echo "run postmap /etc/postfix/transport and service postfix restart."
echo
