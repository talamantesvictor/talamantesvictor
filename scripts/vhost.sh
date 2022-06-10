#!/bin/bash

NGINX_PATH=/etc/nginx
LETSENCRYPT_PATH=/etc/letsencrypt

function help {
   echo "Usage: vhost <action> [options...] <target_domain>" 
   echo "Add or remove Nginx server configuration files for the domain specified" 
   echo "and automatically generates an SSL certificate using certbot."
   echo ""
   echo "Actions:"
   echo "   add               Add the configuration files and SSL certificate."
   echo "   remove            Remove the configuration files and SSL certificate."
   echo ""
   echo "Options:"
   echo "   -p {port}         Docker port to be used. Default: None, filesystem."
   echo "   -n {naked_domain} Add redirect of naked_domain to target_domain."
   echo "   -s                Secure mode. Add redirect from port 80 to 443."
   echo ""
   echo "Eg. vhost add -p 9001 -s www.somedomain.com"
}

# argument validation & handling
# ------------------------------

BADARGS=0
# two arguments minimum
if [[ ${#} -lt 2 ]]; then
   BADARGS=1
fi
# first argument should be add | remove
if [[ $1 != 'add' ]]; then
   if [[ $1 != 'remove' ]]; then
      BADARGS=1
   fi
fi
# if any argument is incorrect
if [[ $BADARGS -eq 1 ]]; then
   help
   exit 1
fi

ACTION=$1
DOMAIN=${@: -1}


if [ -z "$DOMAIN" ]; then
   help
   echo "target domain is missing."
   exit 1;
fi

if [[ $ACTION == 'add' ]]; then
   # read options and show help if any doesn't belong to the script
   optstring="p:n:s"
   shift
   while getopts ${optstring} option; do
      OPTIND=1
      shift
      case "${option}" in
         p) PORT=$1; shift;;
         n) NAKED=$1; shift;;
         s) SECURE=$1; shift;;
         ?) help;;
      esac
   done
else
   FILE_FOUND=0

   # Remove file from sites-enabled
   if [ -L "$NGINX_PATH/sites-enabled/$DOMAIN" ]; then
      rm $NGINX_PATH/sites-enabled/$DOMAIN
      echo "- removed from sites-enabled."
      FILE_FOUND=1;
   fi
   # Remove file from sites-available
   if [ -f "$NGINX_PATH/sites-available/$DOMAIN" ]; then
      rm $NGINX_PATH/sites-available/$DOMAIN
      echo "- removed from sites-available."
      FILE_FOUND=1;
   fi

   # Restart nginx
   if [ $FILE_FOUND = 1 ]; then
      # Remove certificates
      if [ -f "$LETSENCRYPT_PATH/live/$DOMAIN/fullchain.pem" ]; then
         certbot delete --cert-name $DOMAIN
         echo "- removed SSL certificates."
      fi
      echo "- restarting nginx..."
      systemctl restart nginx
   fi

   echo "- process completed."
fi

# nginx templates
# ---------------

CONFIG_TEMP="
server {
   server_name $DOMAIN;
   root /var/www/404;
   index index.html
   listen 80;
}
"
CONFIG_DOCKER="
server {
   server_name $DOMAIN;
   location / {
      proxy_pass http://localhost:$PORT;
		proxy_set_header Host \$http_host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-Proto \$scheme;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
	}
	listen 443 ssl;
	ssl_certificate $LETSENCRYPT_PATH/live/$DOMAIN/fullchain.pem; 
	ssl_certificate_key $LETSENCRYPT_PATH/live/$DOMAIN/privkey.pem; 
	include $LETSENCRYPT_PATH/options-ssl-nginx.conf; 
	ssl_dhparam $LETSENCRYPT_PATH/ssl-dhparams.pem; 
}
"
CONFIG_LOCAL="
server {
	server_name $DOMAIN;
	root /var/www/$DOMAIN;
	index index.html;
	
	listen 443 ssl; # managed by Certbot
	ssl_certificate $LETSENCRYPT_PATH/live/$DOMAIN/fullchain.pem; 
	ssl_certificate_key $LETSENCRYPT_PATH/live/$DOMAIN/privkey.pem; 
	include $LETSENCRYPT_PATH/options-ssl-nginx.conf; 
	ssl_dhparam $LETSENCRYPT_PATH/ssl-dhparams.pem; 
}
"
CONFIG_STRICT_OFF_DOCKER="
server {
	server_name $DOMAIN;
	location / {
		proxy_pass http://localhost:$PORT;
		proxy_set_header Host \$http_host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-Proto \$scheme;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
	}
	listen 80;
}
"
CONFIG_STRICT_OFF_LOCAL="
server {
	server_name $DOMAIN;
	root /var/www/$DOMAIN;
	index index.html;
	listen 80;
}
"
CONFIG_STRICT_ON="
server {
	server_name $DOMAIN;
	return 301 https://\$host\$request_uri;
	listen 80;
}
"
CONFIG_NAKED="
server {
	server_name $NAKED;
	return 301 https://www.\$host\$request_uri;
	listen 80;
	listen 443;

	ssl_certificate $LETSENCRYPT_PATH/live/$DOMAIN/fullchain.pem; 
	ssl_certificate_key $LETSENCRYPT_PATH/live/$DOMAIN/privkey.pem; 
	include $LETSENCRYPT_PATH/options-ssl-nginx.conf; 
	ssl_dhparam $LETSENCRYPT_PATH/ssl-dhparams.pem; 
}
"

