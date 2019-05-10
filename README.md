# rspamd_installer
Installer script for Rspamd

The script will install Rspamd spam filter on a minimal install Debian.
It will act as a spam filter, which will relay all mails to a destination server.
It will also install the necessary software and some addition optional component.

- basic linux tools
- rspamd required modules (unbound, redis-server, clamav)
- apache2 web server
- postfix mail server (optional)
- shorewall firewall (optional)
- letsencrypt certificate (optional)
- webmin (optional)
- munin (optional)

<b>Using the installer:</b>

wget https://raw.githubusercontent.com/hiandras/rspamd_installer/master/rspamd_installer.sh

Make it executable and run it!

When installation complete, you should add your own domain names to postfix's
/etc/postfix/transport file, run postmap /etc/postfix/transport and restart postfix service.
