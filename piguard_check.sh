#!/bin/bash
##################################################################
# Title:     piguard_check
# Copyright (C) 2014 Neighborhood Guard, Inc. All rights reserved
# Author:    Jesper Jurcenoks, Neighborhood Guard
# Version:   1.1
#
# piguard_check is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# piguard_check is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with piguard_check.  If not, see <http://www.gnu.org/licenses/>.
#
################################################################################
# 
#
# Inspired by: WiFi_Check - A Project of TNET Services, Inc
#            Author:    Kevin Reed (Dweeber) (MIT License)
#                       dweeber.dweebs@gmail.com
#            Project:   Raspberry Pi Stuff
#                       https://github.com/dweeber/WiFi_Check
#
# Purpose:
#
# Check various known error conditions on Raspberry Pi seen in connection with
# the PiGuard Setup and try to fix them.
# This is not a perfect solution, ideally we should find the root cause for the
# problems in the first place (proactive) instead of trying to fix them after
# failure - but honesty right now this is all we have resources to do.
#
# Specific Problem 1
# if eth0 is not connected or it is connected to a device that
# has not powered on its ethernet interface, then isc-dhcp-server
# will fail to start. This means dhcp-clients attached to the
# Raspberry being unable to obtain an IP address via dhcp
#
# This script checks to see if dhcp is running and if not
# restart dhcp then toggle eth0 to force attached devices to
# renew their dhcp lease
#
# Specific Problem 2
#
# Wifi or lan interface is down in such a way that there is no IP address assigned
# to the interface, bounce the interface.
#
# Specific Problem 3
#
# Check if ftp_upload is running and restart it if is not.
#
# Uses a lock file which prevents the script from running more
# than one at a time.  If lockfile is old, it removes it
#
# Instructions:
#
# o Install where you want to run it from like ~/ftp_upload
# o chmod +x ~/ftp_upload/piguard_check.sh
# o Add to crontab
#
# Run 1 min after boot and then every 5 min
# Note sudo must be used on raspbian to execute in /usr/local/bin
# so make sure you are usings sudo's crontab like this
#
# sudo crontab -e
#
# @reboot  sleep 60 && ~/ftp_upload/piguard_check.sh
# */5 * * * * /usr/local/bin/piguard_check.sh
#
##################################################################
# Settings
# Where and what you want to call the Lockfile
HOMEDIR=~
lockfile=$HOMEDIR'/ftp_upload/piguard_check.pid'
##################################################################
echo
echo "Starting piguard_check"
date
echo 
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

function if_bounce() {
    echo "Network connection down! Attempting reconnection."
    sudo ifdown $1
    sleep 5
    sudo ifup --force $1
    ifconfig $1 | grep "inet addr"
}


function ip_address_check(){
    # We can perform check
    echo "Performing Network check for $1"
    if ifconfig $1 | grep -q "inet addr:" ; then
        echo "Network is Okay"
    else
        if_bounce $1
    fi

    echo 
    echo "Current Setting:"
    ifconfig $1 | grep "inet addr:"
    echo
}



function check_create_lockfile() {
    echo "lockfile name:$lockfile"
    # Check to see if there is a lock file
    if [ -e $lockfile ]
    then
        echo "lockfile found"
        # A lockfile exists... Lets check to see if it is still valid
        pid=`cat $lockfile`
        if kill -0 &>1 > /dev/null $pid; then
            # Still Valid... lets let it be...
            #echo "Process still running, Lockfile valid"
            exit 1
        else
            # Old Lockfile, Remove it
            #echo "Old lockfile, Removing Lockfile"
            rm $lockfile
        fi
    fi
    # If we get here, set a lock file using our current PID#
    echo "Setting Lockfile"
    echo "$$" > $lockfile
    echo "lockfile should be set now"
}


function check_dhcp() {
    # Which Interface do you want to toogle once dhcp is started
    eth='eth0'

    # Perform check
    echo "Performing service running check for dhcp"
    if ps -A  | grep -q "dhcpd" ; then
        echo "dhcpd is Running"
    else
        echo "dhcpd not running"
        echo "attempting restart of dhcd"
        service isc-dhcp-server start
        echo "taking eth0 down and up to force dhcpclient to retry getting an ip address"
        ifbounce $eth
        ifconfig $eth | grep "inet addr"
    fi
}

function check_connectivity() {
    # Perform check
    echo "Performing ping check to $2"
    if ping -c 4 $2; then
        echo "connectivity to $2 confirmed"
    else
        echo "no conectivity to $2"
        if_bounce $1
    fi
}

# Check Create Lock File
check_create_lockfile

# Check Wifi ip address
ip_address_check wlan0

# Check Lan ip address
ip_address_check eth0

# Check dhcp
check_dhcp

# Check connectivity to internet (google)
check_connectivity wlan0 "www.google.com"

# Check connectivity to camera 
check_connectivity eth0 "10.19.12.2"

# Check is complete, Remove Lock file and exit
#echo "process is complete, removing lockfile"
rm $lockfile
exit 0

##################################################################
# End of Script
##################################################################
