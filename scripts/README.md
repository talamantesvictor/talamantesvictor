# Victor's scripts
All scripts on this repository were coded by and for Victor Talamantes. They are not meant to be used by others but you are free to use them if you find them useful.

### vhost
**Language:** Bash<br>
**Dependencies:** Nginx, certbot, systemctl
```
Usage: vhost <action> [options...] <target_domain>
Add or remove Nginx server configuration files for the domain specified
and automatically generates an SSL certificate using certbot.

Actions:
   add               Add the configuration files and SSL certificate.
   remove            Remove the configuration files and SSL certificate.

Options:
   -p {port}         Docker port to be used. Default: None, filesystem.
   -n {naked_domain} Add redirect of naked_domain to target_domain.
   -s                Secure mode. Add redirect from port 80 to 443.

Eg. vhost add -p 9001 -s www.somedomain.com
```
<br>

<a href='https://ko-fi.com/Q5Q4D7835' target='_blank'><img height='44' style='border:0px;height:44px;' src='https://cdn.ko-fi.com/cdn/kofi3.png?v=3' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
