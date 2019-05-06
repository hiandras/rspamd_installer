# rspamd_installer
Installer script for Rspamd

The script will install Rspamd spam filter on a minimal install Debian.
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

wget https://github.com/hiandras/rspamd_installer/blob/master/rspamd_installer.sh
Make it executable and run it!
