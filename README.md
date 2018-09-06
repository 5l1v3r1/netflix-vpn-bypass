# netflix-vpn-bypass
Bypass the OpenVPN Client and selectively route Netflix traffic to the WAN interface on **Asuswrt-Merlin** firmware.  Similarly, the updated versions of the scripts will also allow you to route Netflix traffic to an OpenVPN client, rather than the WAN, by editing the FWMARK parameter in the **create_routing_rules** function.  

Since January 2016, Netflix blocks known VPN servers.  The purpose of the **IPSET_Netflix.sh** and **IPSET_Netflix_Domains** script is to bypass the OpenVPN Client for Netflix traffic and route it to the WAN interface.  Netflix hosts on Amazon AWS servers. As a result, Amazon AWS domains also need to be included.

There are two methods used in this project.  

**IPSET_Netflix.sh** collects the IPv4 addresses used by Netflix from https://ipinfo.io using the Autonomous System Number (ASN) assigned to Netflix. Amazon AWS supplies the list of IPv4 addresses in the json file at
https://ip-ranges.amazonaws.com/ip-ranges.json

Only the Amazon AWS US Regions are extracted from ip-ranges.json. As a result, the script will also route all Amazon AWS traffic bound for the US, including Amazon Prime traffic, to the WAN interface.

**IPSET_Netflix_Domains.sh** uses the feature of IPSET built into dnsmasq to dynamically generate the IPv4 address used by Netflix and Amazon AWS dynamically.  This approach can be useful when a Content Delivery Network (CDN) is used.  This method has the benefit of being more specific in the domains used to route Netflix traffic to the WAN.

#### Requirements

1. Installation of [entware]( https://github.com/RMerl/asuswrt-merlin/wiki/Entware).  The **/opt/tmp** directory on entware is used to store the files containing the IPv4 addresses for the **IPSET_Netflix.sh** script and the backup IPSET list file for the **IPSET_Netflix_Domains.sh** script.  
2. The entware package **jq** is required by the **IPSET_Netflix.sh** script. **jq** is a json file parser.  To install **jq**, enter the command ```opkg install jq``` on the command line.
3. ipset version 6. Support for ipset version 4.5 is planned for a future release. To confirm the version you have installed, type ```ipset -v```
4. OpenVPN Client Settings:
    - set **Redirect Internet traffic** to **Policy Rules** or **Policy Rules (Strict)**
    - dnsmasq is bypassed when **Accept DNS Configuration** is set to **Exclusive**.  I recommend setting **Accept DNS Configuration**  to **Strict**. In the **Custom Config** section, specify a DNS server of your choice using the command ```dhcp-option DNS xxx.xxx.xxx.xxx``` where the xxx's are a DNS server of your choice. For example:
    ```dhcp-option DNS 1.1.1.1```

### IPSET_Netflix.sh
Autonomous System Numbers (ASNs) are assigned to entities such as Internet Service Providers and other large organizations that control blocks of IP addresses. The ASN for Netflix is AS2906.  

This script will:
1. Create the IPSET lists x3mRouting_NETFLIX and x3mRouting_AMAZONAWS
2. Obtain the IPv4 addresses used by Netflix using AS2906 from ipinfo.io.
3. Add the Netflix IPv4 address to the IPSET list x3mRouting_NETFLIX
4. Parse the Amazon AWS json file using the jq entware package for IPv4 addresses used by Amazon in the US Region
5. Add the Amazon IPv4 address to the IPSET list x3mRouting_AMAZONAWS
6. Route IPv4 addresses in IPSET lists x3mRouting_NETFLIX and x3mRouting_NETFLIX to the WAN interface

IPv6 addresses are excluded in this version.

#### Installation

    /usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/Xentrk/netflix-vpn-bypass/master/IPSET_Netflix.sh" -o /jffs/scripts/IPSET_Netflix.sh

### IPSET_Netflix_Domains.sh
**IPSET_Netflix_Domains.sh** uses the feature of ipset in dnsmasq to dynamically generate the IPv4 address used by Netflix and Amazon AWS dynamically.  The script will create a cron job that will backup the IPSET list at 2:00 am.  The backup will be used to restore the IPSET list upon system startup.  

This approach can be useful when Content Delivery Networks (CDN) are used.  The domains names used may vary by region. As a result, you may have to do some analysis to determine the domain names Netflix is using.

To determine the domain names, download the script **getdomainnames.sh** to **/jffs/scripts/getdomainnames.sh** and make it executable:

```chmod 755 getdomainnames.sh```

Navigate to the dnsmasq log file directory.  My dnsmasq.log file location is **/opt/var/log**.   

Turn off the VPN for this test so your Netflix traffic can traverse thru the WAN. Navigate to the dnsmasq log file directory **/opt/var/log**. Type the command to start capturing domains used by Netflix:

    tail -f dnsmasq.log > Netflix

Now, go to the device you are watching Netflix from. Navigate around the Netflix menu options and watch several videos for a few minutes each to generate traffic.  If you are streaming from your PC or laptop, close out of all other applications to minimize collecting domain names for non-Netflix traffic.

When done generating Netflix traffic, press **ctrl-C** to stop logging to the **/opt/var/log/Netflix** file.  Run the **getdomainnames.sh** script, passing the **file name** and **IP address** of the device you were watching Netflix from:

    . /jffs/scripts/getdomainnames.sh Netflix 192.168.1.20

This will create a file called **Netflix_domains** in the **/opt/var/log** directory.  You can now see the domains being called when watching Netflix. You will need to desk check the file for domains that are not related to Netflix that may have been generated by other applications by the LAN client you streamed Netflix from. You will then need to update the **ipset=** references in the **IPSET_Netflix_Domains.sh** script to use the domain names you captured. Do not use the fully qualified domain name. You only need to provide the domain name in the format of netflix.net, netflix.com, or amazonaws.com. For example, the domain **occ-0-1077-1062.1.nflxso.net** would be entered as **nflxso.net**.

#### Installation
    /usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/Xentrk/netflix-vpn-bypass/master/getdomainnames.sh" -o /jffs/scripts/getdomainnames.sh && chmod 755 /jffs/scripts/getdomainnames.sh

    /usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/Xentrk/netflix-vpn-bypass/master/IPSET_Netflix_Domains.sh" -o /jffs/scripts/IPSET_Netflix_Domains.sh

### Troubleshooting
```ipset -L x3mRouting_NETFLIX``` command will list the contents of the IPSET list x3mRouting_NETFLIX

```iptables -nvL PREROUTING -t mangle --line``` will display the PREROUTING Chain statistics.

```ip rule``` will display the rules and priorities for the LAN clients and the fwmark/bitmask created for the WAN interface.

  Support available on [snbforums.com](https://www.snbforums.com/threads/selective-routing-for-netflix.42661/)
