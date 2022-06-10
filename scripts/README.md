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

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/talamantesvic)
