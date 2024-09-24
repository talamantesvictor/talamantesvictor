#!/bin/bash
# Easily add server configurations to Caddy and ensure SSL is automatically enabled.
# Dependencies:
# - caddy
# - systemctl

CADDY_PATH=/etc/caddy

function help {
   echo "Usage: caddyhost <action> [options...] <target_domain>"
   echo "Add or remove Caddy server configuration files for the domain specified"
   echo ""
   echo "Actions:"
   echo "   add               Add the configuration files."
   echo "   remove            Remove the configuration files."
   echo ""
   echo "Options:"
   echo "   -p {port}         Docker port to be used for reverse proxy. Default: filesystem."
   echo "   -n {naked_domain} Add redirect of naked_domain to target_domain."
   echo "   -a                Enable Angular/SPA mode for path handling (only for filesystem, not Docker)."
   echo ""
   echo "Eg. caddyhost add -p 9001 www.somedomain.com"
   echo "    caddyhost add -n somedomain.com www.somedomain.com"
   echo "    caddyhost add -a www.angularapp.com"
   echo "    caddyhost remove www.somedomain.com"
}

# Argument validation & handling
# ------------------------------
BADARGS=0
SPA_MODE=0
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
   echo "Target domain is missing."
   exit 1
fi

if [[ $ACTION == 'add' ]]; then
   # Read options
   optstring="p:n:a"
   shift
   while getopts ${optstring} option; do
      OPTIND=1
      shift
      case "${option}" in
         p) PORT=$1; shift;;
         n) NAKED=$1; shift;;
         a) SPA_MODE=1;;  # Activate SPA mode for Angular/SPA (only for filesystem)
         ?) help;;
      esac
   done

   # Caddyfile templates for reverse proxy (Docker)
   CONFIG_DOCKER="
   $DOMAIN {
      reverse_proxy localhost:$PORT
   }
   "

   # Local configuration for static files (filesystem)
   CONFIG_LOCAL="
   $DOMAIN {
      root * /var/www/$DOMAIN
      file_server
   }
   "

   # SPA mode (only for filesystem, not Docker)
   if [[ $SPA_MODE -eq 1 && -z "$PORT" ]]; then
      CONFIG_LOCAL="
      $DOMAIN {
         root * /var/www/$DOMAIN
         file_server
         try_files {path} /index.html
      }
      "
   fi

   CONFIG_NAKED="
   $NAKED {
      redir https://$DOMAIN{uri}
   }
   "

   # Define the path for the individual Caddyfile
   FILE=$CADDY_PATH/sites/$DOMAIN.caddy

   if [ -f "$FILE" ]; then
      echo "$FILE already exists. Skipping Caddy configuration."
   else
      echo "- creating Caddy configuration..."
      mkdir -p $CADDY_PATH/sites

      if [ -z "$PORT" ]; then
         echo "$CONFIG_LOCAL" > $FILE
      else
         echo "$CONFIG_DOCKER" > $FILE
      fi

      if [ ! -z "$NAKED" ]; then
         echo "$CONFIG_NAKED" >> $FILE
      fi

      # Reload Caddy to apply the new configuration
      systemctl reload caddy
      echo "- $DOMAIN was added successfully and Caddy reloaded."
   fi

else # remove action
   FILE_FOUND=0
   FILE=$CADDY_PATH/sites/$DOMAIN.caddy

   # Remove file from Caddy sites
   if [ -f "$FILE" ]; then
      rm $FILE
      echo "- removed $FILE."
      FILE_FOUND=1
   fi

   # Restart Caddy if changes were made
   if [ $FILE_FOUND = 1 ]; then
      echo "- restarting Caddy..."
      systemctl reload caddy
   fi

   echo "- process completed."
fi
