# check_paloalto.pl
A Nagios plugin based on Perl and SNMPv3 to check the status of a Palo Alto Networks device.

| @27th January 2025 | Version |
|---------------:|----------|
| Tested on      |  PA-440 |
| PAN-OS         |  11.2.4-h2 |
| Nagios Core    |  4.5.9 |

<sub>Unsure who the author is. Credits to the unknown author.</sub>

[![GitHub release](https://img.shields.io/github/release/FoUStep/check_paloalto.pl.svg)](https://GitHub.com/FoUStep/check_paloalto.pl/releases/)

<sub>Due to security reasons this is SNMPv3 only.</sub>
```
# check_paloalto.pl 
Usage:
./check_paloalto.pl -H [ip|fqdn] -u [username] -A [authpassword] -X [privpassword] -t [system|temp|cpu|ha|sessions|icmp_sessions|vpn] -w [warning value] -c [critical value]

-H = IP/FQDN of the PA
-u = Username
-A = AuthPassword
-X = PrivPassword
-t = Check type (currently only system/temp/cpu/ha/sessions/icmp_sessions/vpn)
-w = Warning Value
-c = Critical Value
```
