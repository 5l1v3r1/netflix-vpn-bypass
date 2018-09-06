#!/bin/sh
set -x
# This script will format the output of tail -f dnsmasq.log > logfile
# where logfile is the output of tail -f dnsmasq.log
#  1. extract records whose contents contain the word "query" and the IP address of the
#     client that is generating the taffic.
#  2. output only the domain names
#  3. sort file for unique contents to eliminate duplicates
#  4. save to $1_domains
#
# Parameters Passed
# $1 = provide the name of the source file when running the script
#     e.g. ./getdomainnames.sh logfile IPv4_Address
#
source_file=/opt/var/log/$1
output_file="${source_file}_domains"
IP=$2

cat $source_file | grep query | grep "$IP" | awk '{ print $6 }' | sort -u > "$output_file"
