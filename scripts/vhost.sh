#!/bin/bash

function help {
   echo "Usage: vhost {action} [options...] {target_domain}" 
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

if [[ ${#} -eq 0 ]]; then
   help
fi

