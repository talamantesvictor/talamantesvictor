# Victor's scripts
All scripts on this repository were coded by and for Victor Talamantes. They are not meant to be used by others but be free to do so, under your own risk, if you find them useful.

### vhost
**Language:** Bash  
**Dependencies:** Nginx, certbot, systemctl

```
Usage: vhost <action> [options...] <target_domain>  
Add or remove Nginx server configuration files for the domain specified, and automatically generate an SSL certificate using certbot.

Actions:
   add               Add the configuration files and SSL certificate.
   remove            Remove the configuration files and SSL certificate.

Options:
   -p {port}         Docker port to be used for reverse proxy. Default: filesystem.
   -n {naked_domain} Add redirect of naked_domain to target_domain.
   -s                Secure mode. Add redirect from port 80 to 443.
   -a                Enable Angular/SPA mode for path handling (only for filesystem, not Docker).

Eg.  
   vhost add -p 9001 -s www.somedomain.com  
   vhost add -n somedomain.com -s www.somedomain.com  
   vhost add -a www.angularapp.com  
   vhost remove www.somedomain.com
```
<br>

### caddyhost
**Language:** Bash  
**Dependencies:** Caddy, systemctl

```
Usage: caddyhost <action> [options...] <target_domain>  
Add or remove Caddy server configuration files for the domain specified, supporting automatic SSL (handled by Caddy).

Actions:
   add               Add the configuration files.
   remove            Remove the configuration files.

Options:
   -p {port}         Docker port to be used for reverse proxy. Default: filesystem.
   -n {naked_domain} Add redirect of naked_domain to target_domain.
   -a                Enable Angular/SPA mode for path handling (only for filesystem, not Docker).

Eg.  
   caddyhost add -p 9001 www.somedomain.com  
   caddyhost add -n somedomain.com www.somedomain.com  
   caddyhost add -a www.angularapp.com  
   caddyhost remove www.somedomain.com
```
<br>

### gitsync
**Language:** Bash<br>
**Dependencies:** Git
```
Look for git repositories in all subfolders and sync them with their remote. 
This script is intended for automated backups.
```
<br>

<a href='https://ko-fi.com/Q5Q4D7835' target='_blank'><img height='44' style='border:0px;height:44px;' src='https://cdn.ko-fi.com/cdn/kofi3.png?v=3' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

---
All files and scripts in this repository are licensed under the MIT License.
