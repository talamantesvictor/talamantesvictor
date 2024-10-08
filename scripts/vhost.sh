#!/bin/bash
# Easily add server configurations to Nginx and generate an SSL certificate.
# Dependencies:
# - nginx
# - certbot
# - systemctl

NGINX_PATH=/etc/nginx
LETSENCRYPT_PATH=/etc/letsencrypt
SPA_MODE=0

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
   echo "   -a                Enable Angular/SPA mode for path handling (only for filesystem, not Docker)."
   echo ""
   echo "Eg. vhost add -p 9001 -s www.somedomain.com"
   echo "    vhost add -n somedomain.com -s www.somedomain.com"
   echo "    vhost remove www.somedomain.com"
}

# Argument validation & handling
# ------------------------------

BADARGS=0
if [[ ${#} -lt 2 ]]; then
   BADARGS=1
fi
if [[ $1 != 'add' && $1 != 'remove' ]]; then
   BADARGS=1
fi
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
   optstring="p:n:sa"
   shift
   while getopts ${optstring} option; do
      OPTIND=1
      shift
      case "${option}" in
         p) PORT=$1; shift;;
         n) NAKED=$1; shift;;
         s) SECURE=1;;
         a) SPA_MODE=1;;  # Enable SPA mode only for filesystem
         ?) help;;
      esac
   done

   # nginx templates for reverse proxy (Docker)
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

   # Standard local configuration for static files (filesystem)
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

   # SPA configuration with try_files (only for filesystem)
   if [[ $SPA_MODE -eq 1 && -z "$PORT" ]]; then
      CONFIG_LOCAL="
      server {
         server_name $DOMAIN;
         root /var/www/$DOMAIN;
         index index.html;

         location / {
            try_files \$uri \$uri/ /index.html?\$args;
         }

         listen 443 ssl; # managed by Certbot
         ssl_certificate $LETSENCRYPT_PATH/live/$DOMAIN/fullchain.pem; 
         ssl_certificate_key $LETSENCRYPT_PATH/live/$DOMAIN/privkey.pem; 
         include $LETSENCRYPT_PATH/options-ssl-nginx.conf; 
         ssl_dhparam $LETSENCRYPT_PATH/ssl-dhparams.pem;
      }
      "
   fi

   CONFIG_SECURE_OFF_DOCKER="
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
   CONFIG_SECURE_OFF_LOCAL="
   server {
      server_name $DOMAIN;
      root /var/www/$DOMAIN;
      index index.html;
      listen 80;
   }
   "
   CONFIG_SECURE_ON="
   server {
      server_name $DOMAIN;
      return 301 https://$DOMAIN\$request_uri;
      listen 80;
   }
   "
   CONFIG_NAKED="
   server {
      server_name $NAKED;
      return 301 https://$DOMAIN\$request_uri;
      listen 80;
   }
   "

   FILE=$NGINX_PATH/sites-available/$DOMAIN

   if [ -f "$FILE" ]; then
      # if file exists
       echo "$FILE already exists. Skip nginx configuration."
   else
      # if file doesn't exists
      echo "- adding temp configuration..."
      echo "$CONFIG_TEMP" > $FILE
      certbot certonly -d $DOMAIN --nginx
      echo "- let's encrypt certificate generated."
      rm $FILE
      echo "- creating nginx configuration..."
      if [ -z "$PORT" ]; then
         echo "$CONFIG_LOCAL" > $FILE
         if [ -z "$SECURE" ]; then
            echo "$CONFIG_SECURE_OFF_LOCAL" >> $FILE
         else 
            echo "$CONFIG_SECURE_ON" >> $FILE
         fi
      else
         echo "$CONFIG_DOCKER" > $FILE
         if [ -z "$SECURE" ]; then
            echo "$CONFIG_SECURE_OFF_DOCKER" >> $FILE
         else 
            echo "$CONFIG_SECURE_ON" >> $FILE
         fi
      fi
      if [ ! -z "$NAKED" ]; then
         echo "$CONFIG_NAKED" >> $FILE
      fi
      ln -s $FILE $NGINX_PATH/sites-enabled
      echo "- $DOMAIN was added successfully."
      systemctl restart nginx
      echo "- nginx restarted."
      echo "- process complete."
   fi

else # remove action
   FILE_FOUND=0

   # remove file from sites-enabled
   if [ -L "$NGINX_PATH/sites-enabled/$DOMAIN" ]; then
      rm $NGINX_PATH/sites-enabled/$DOMAIN
      echo "- removed from sites-enabled."
      FILE_FOUND=1;
   fi
   # remove file from sites-available
   if [ -f "$NGINX_PATH/sites-available/$DOMAIN" ]; then
      rm $NGINX_PATH/sites-available/$DOMAIN
      echo "- removed from sites-available."
      FILE_FOUND=1;
   fi

   # restart nginx
   if [ $FILE_FOUND = 1 ]; then
      # remove certificates
      if [ -f "$LETSENCRYPT_PATH/live/$DOMAIN/fullchain.pem" ]; then
         certbot delete --cert-name $DOMAIN
         echo "- removed SSL certificates."
      fi
      echo "- restarting nginx..."
      systemctl restart nginx
   fi

   echo "- process completed."
fi
