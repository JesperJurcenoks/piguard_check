#piguard_check#

###Summary###

piguard_check.sh is part of a software suite from [Neighborhood Guard](http://neighborhoodguard.org) to upload images from IP cameras and organize them into Web pages for easy access and review.

piguard_check.sh is a script intended run on a Raspberry Pi that serves an IP camera.  The camera get its IP address from the Raspberry Pi dhcp server.  If the Raspberry Pi comes online before the Camera on a direct connection setup (no hub or switch) then the isc-dhcp-server on the raspberry will fail to start as the ethernet is seen as down.

This script will check to see if the dhcp daemon is not running at start it as needed. After starting the dhcpd, the script will toggle the eth port down and up to force a renew of the dhcp lease by the Ip camera

This script will also determine Wifi connectivity to the internet (www.google.com) and lan connectivity to the camera. If either is absent it will bounce the interface.

This script will determine if the debug tunnel is up and bring it back up if not.

###Installation and Configuration###

Download piguard_check.sh to /usr/local/bin

sudo wget https://raw.github.com/JesperJurcenoks/piguard_check/master/piguard_check.sh -O /usr/local/bin/piguard_check.sh

Give piguard_check.sh execute rights 

sudo chmod +x /usr/local/bin/piguard_check.sh

Setup Cron entry

sudo crontab -e 

add the following line at the end of the crontab

*/5 * * * * sudo /usr/local/bin/piguard_check.sh


###License###

piguard_check is open-source software available under the terms of the Affero GPL 3.0 license.  If the Affero GPL license does not meet your needs, other licensing arrangements are available from Neighborhood Guard, Inc.

###Contact Information###
If you have questions about this software, please contact:

Douglas Kerr, dougk at halekerr dot com, Board member for Software

or, 

Jesper Jurcennoks, jesper at jurcenoks dot com, President, Neighborhood Guard
