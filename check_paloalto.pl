#!/usr/bin/env perl

###########################################
###########################################
##
## temp|system|cpu|ha|vpn|
## |sessions|icmp_sessions
##
## Tested on PA-440 by Step @ 18th May 2023
##
###########################################
###########################################


use strict;
use lib "/usr/lib/nagios/plugins/";
use Net::SNMP;
my $stat;
my $msg;
my $perf;
my $script_name = "check_paloalto.pl";
my $script_version = 1.0.0;


### SNMP OIDs
###############
my $s_cpu_mgmt = '.1.3.6.1.2.1.25.3.3.1.2.1';
my $s_cpu_data = '.1.3.6.1.2.1.25.3.3.1.2.2';
my $s_firmware = '.1.3.6.1.2.1.25.3.3.1.2.2';
my $s_firmware_version = '.1.3.6.1.4.1.25461.2.1.2.1.1.0';
my $s_ha_mode = '.1.3.6.1.4.1.25461.2.1.2.1.13.0';
my $s_ha_local_state = '.1.3.6.1.4.1.25461.2.1.2.1.11.0';
my $s_ha_peer_state = '.1.3.6.1.4.1.25461.2.1.2.1.12.0';
my $s_pa_model = '.1.3.6.1.4.1.25461.2.1.2.2.1.0';
my $s_pa_max_sessions = '.1.3.6.1.4.1.25461.2.1.2.3.2.0';
my $s_pa_total_active_sessions = '.1.3.6.1.4.1.25461.2.1.2.3.3.0';
my $s_pa_total_tcp_active_sessions = '.1.3.6.1.4.1.25461.2.1.2.3.4.0';
my $s_pa_total_udp_active_sessions = '.1.3.6.1.4.1.25461.2.1.2.3.5.0';
my $s_pa_total_icmp_active_sessions = '.1.3.6.1.4.1.25461.2.1.2.3.6.0';
my $s_uptime = '1.3.6.1.2.1.25.1.1.0';
my $s_tempCPU = '1.3.6.1.2.1.99.1.1.1.4.2';
my $s_gp_vpn_tunnels = '1.3.6.1.4.1.25461.2.1.2.5.1.3.0';

### Functions
###############
sub _create_session {
    my ($server, $user, $auth, $priv) = @_;
    my $snmp_version = 3;
    my $authproto = 'sha';
    my $privproto = 'aes';
    my ($sess, $err) = Net::SNMP->session( -hostname => $server, -version => $snmp_version, -username => $user, -authpassword => $auth, -authprotocol => $authproto, -privpassword => $priv, -privprotocol => $privproto );
    if (!defined($sess)) {
        print "Can't create SNMPv$snmp_version session to $server. Reason: $err \n";
        exit(1);
    }
    return $sess;
}

sub FSyntaxError {
    print "Syntax Error!\n";
    print "\n";
    print "Usage:\n";
    print "$0 -H [ip|fqdn] -u [username] -A [authpassword] -X [privpassword] -t [system|temp|cpu|ha|sessions|icmp_sessions|vpn] -w [warning value] -c [critical value]\n";
    print "\n";
    print "$script_name\n";
    print "Script version: $script_version\n";
    print "-H = IP/FQDN of the PA\n";
    print "-u = Username\n";
    print "-A = AuthPassword\n";
    print "-X = PrivPassword\n";
    print "-t = Check type (currently only system/temp/cpu/ha/sessions/icmp_sessions/vpn)\n";
    print "-w = Warning Value\n";
    print "-c = Critical Value\n";
    exit(3);
}

if($#ARGV != 13) {
    FSyntaxError;
}

### Gather input from user
#############################
my $host;
my $username;
my $authpasswd;
my $privpasswd;
my $check_type;
my $warn = 0;
my $crit = 0;
my $int;

while(@ARGV) {
    my $temp = shift(@ARGV);
    if("$temp" eq '-H') {
        $host = shift(@ARGV);
    } elsif("$temp" eq '-u') {
        $username = shift(@ARGV);
    } elsif("$temp" eq '-A') {
        $authpasswd = shift(@ARGV);
    } elsif("$temp" eq '-X') {
        $privpasswd = shift(@ARGV);
    } elsif("$temp" eq '-t') {
        $check_type = shift(@ARGV);
    } elsif("$temp" eq '-w') {
        $warn = shift(@ARGV);
    } elsif("$temp" eq '-c') {
        $crit = shift(@ARGV);
    } else {
        FSyntaxError();
    }
}

# Validate Warning
if($warn > $crit) {
    print "Warning can't be larger then Critical: $warn > $crit\n";
    FSyntaxError();
}

# Establish SNMP Session
our $snmp_session = _create_session($host,$username,$authpasswd,$privpasswd);


### SYSTEM INFO ###
if($check_type eq "system") {
    my $R_firm = $snmp_session->get_request(-varbindlist => [$s_pa_model]);
    my $palo_model = "$R_firm->{$s_pa_model}";

    my $R_firm = $snmp_session->get_request(-varbindlist => [$s_uptime]);
    my $pa_uptime = "$R_firm->{$s_uptime}";

    my $R_firm = $snmp_session->get_request(-varbindlist => [$s_firmware_version]);
    my $palo_os_ver = "$R_firm->{$s_firmware_version}";

    $msg = "INFO: $palo_model running PAN-OS version $palo_os_ver - Uptime: $pa_uptime";
    $perf="";
    $stat = 0;
}

### HA MODE ###
elsif($check_type eq "ha") {
    my $R_firm = $snmp_session->get_request(-varbindlist => [$s_ha_mode]);
    my $ha_mode = "$R_firm->{$s_ha_mode}";

    my $R_firm = $snmp_session->get_request(-varbindlist => [$s_ha_local_state]);
    my $ha_local_state = "$R_firm->{$s_ha_local_state}";

    my $R_firm = $snmp_session->get_request(-varbindlist => [$s_ha_peer_state]);
    my $ha_peer_state = "$R_firm->{$s_ha_peer_state}";


    $msg =  "OK: High Availablity Mode:  $ha_mode - Local:  $ha_local_state - Peer:  $ha_peer_state\n";
    $perf="";
    $stat = 0;
}

### SESSIONS ###
elsif($check_type eq "sessions") {
    my $R_firm = $snmp_session->get_request(-varbindlist => [$s_pa_max_sessions]);
    my $pa_max_sessions = "$R_firm->{$s_pa_max_sessions}";

    my $R_firm = $snmp_session->get_request(-varbindlist => [$s_pa_total_active_sessions]);
    my $pa_total_active_sessions = "$R_firm->{$s_pa_total_active_sessions}";

    my $R_tcpfirm = $snmp_session->get_request(-varbindlist => [$s_pa_total_tcp_active_sessions]);
    my $pa_total_tcp_sessions = "$R_tcpfirm->{$s_pa_total_tcp_active_sessions}";

    my $R_udpfirm = $snmp_session->get_request(-varbindlist => [$s_pa_total_udp_active_sessions]);
    my $pa_total_udp_sessions = "$R_udpfirm->{$s_pa_total_udp_active_sessions}";

    if($pa_total_active_sessions > $crit or $pa_total_tcp_sessions > $crit or $pa_total_udp_sessions > $crit ) {
        $msg =  "CRITICAL: Total Sessions:  $pa_total_active_sessions - TCP: $pa_total_tcp_sessions UDP: $pa_total_udp_sessions - Max Sessions: $pa_max_sessions";
        $stat = 2;
    } elsif($pa_total_active_sessions > $warn or $pa_total_tcp_sessions > $warn or $pa_total_udp_sessions > $warn ) {
        $msg =  "WARNING: Total Sessions:  $pa_total_active_sessions - TCP: $pa_total_tcp_sessions UDP: $pa_total_udp_sessions - Max Sessions: $pa_max_sessions";
        $stat = 1;
    } else {
        $msg =  "OK: Total Sessions:  $pa_total_active_sessions - TCP: $pa_total_tcp_sessions UDP: $pa_total_udp_sessions - Max Sessions: $pa_max_sessions";
        $stat = 0;
    }
	$perf = "Total=$pa_total_active_sessions;$warn;$crit;0;65534 tcp=$pa_total_tcp_sessions;$warn;$crit;0;65534 udp=$pa_total_udp_sessions;$warn;$crit;0;65534";
}

### ICMP SESSIONS ###
elsif($check_type eq "icmp_sessions") {
    my $R_firm = $snmp_session->get_request(-varbindlist => [$s_pa_total_icmp_active_sessions]);
    my $pa_total_icmp_active_sessions = "$R_firm->{$s_pa_total_icmp_active_sessions}";


    if($pa_total_icmp_active_sessions > $crit ) {
        $msg =  "CRITICAL: ICMP Active Sessions:  $pa_total_icmp_active_sessions";
        $stat = 2;
    } elsif($pa_total_icmp_active_sessions > $warn ) {
        $msg =  "WARNING: ICMP Active Sessions:  $pa_total_icmp_active_sessions";
        $stat = 1;
    } else {
        $msg =  "OK:   ICMP Active Sessions:  $pa_total_icmp_active_sessions";
        $stat = 0;

    }

        $perf="";

}

### VPN TUNNELS ###
elsif($check_type eq "vpn") {
    my $R_firm = $snmp_session->get_request(-varbindlist => [$s_gp_vpn_tunnels]);
    my $gp_vpn_tunnels = "$R_firm->{$s_gp_vpn_tunnels}";


    if($gp_vpn_tunnels > $crit ) {
        $msg =  "CRITICAL: VPN: $gp_vpn_tunnels tunnel(s)";
        $stat = 2;
    } elsif($gp_vpn_tunnels > $warn ) {
        $msg =  "WARNING: VPN: $gp_vpn_tunnels tunnel(s)";
        $stat = 1;
    } else {
        $msg =  "OK: VPN: $gp_vpn_tunnels tunnel(s)";
        $stat = 0;
    }
	$perf = "VPN-tunnels=$gp_vpn_tunnels;$warn;$crit"
}

### CPU ###
elsif($check_type eq "cpu") {
    my $R_mgmt = $snmp_session->get_request(-varbindlist => [$s_cpu_mgmt]);
    my $mgmt = "$R_mgmt->{$s_cpu_mgmt}";
    my $R_data = $snmp_session->get_request(-varbindlist => [$s_cpu_data]);
    my $data = "$R_data->{$s_cpu_data}";

    if($mgmt > $crit or $data > $crit) {
        $msg = "CRITICAL: Management: $mgmt%, Data: $data%";
        $stat = 2;
    } elsif($mgmt > $warn or $data > $warn) {
        $msg = "WARNING: Management: $mgmt%, Data: $data%";
        $stat = 1;
    } else {
        $msg = "OK: Management: $mgmt%, Data: $data%";
        $stat = 0;
    }
    $perf = "mgmt=$mgmt;$warn;$crit data=$data;$warn;$crit";
}

### TEMP ###
elsif($check_type eq "temp") {
    my $R_CPU = $snmp_session->get_request(-varbindlist => [$s_tempCPU]);
    my $CPU = "$R_CPU->{$s_tempCPU}";

    if($CPU > $crit) {
        $msg = "CRITICAL - CPU Temperature: $CPU°C";
        $stat = 2;
    } elsif($CPU > $warn) {
        $msg = "WARNING - CPU Temperature: $CPU°C";
        $stat = 1;
    } else {
        $msg = "OK - CPU Temperature: $CPU°C";
        $stat = 0;
    }
    $perf = "CPU=$CPU;$warn;$crit";

### Bad Syntax ###

} else {
    FSyntaxError();
}

if ($perf eq "") {
 print "$msg\n";
} else {
 print "$msg | $perf\n";
}

exit($stat);
