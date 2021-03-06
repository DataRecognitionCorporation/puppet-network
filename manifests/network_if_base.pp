# == Definition: network_if_base
#
# This definition is private, i.e. it is not intended to be called directly
# by users.  It can be used to write out the following device files:
#  /etc/sysconfig/networking-scripts/ifcfg-eth
#  /etc/sysconfig/networking-scripts/ifcfg-eth:alias
#  /etc/sysconfig/networking-scripts/ifcfg-bond(master)
#
# === Parameters:
#
#   $ensure          - required - up|down
#   $ipaddress       - optional
#   $netmask         - optional
#   $macaddress      - required
#   $manage_hwaddr   - optional - defaults to true
#   $gateway         - optional
#   $noaliasrouting  - optional - defaults to false
#   $bootproto       - optional
#   $userctl         - optional - defaults to false
#   $mtu             - optional
#   $dhcp_hostname   - optional
#   $ethtool_opts    - optional
#   $bonding_opts    - optional
#   $isalias         - optional
#   $peerdns         - optional
#   $dns1            - optional
#   $dns2            - optional
#   $domain          - optional
#   $bridge          - optional
#   $scope           - optional
#   $linkdelay       - optional
#   $check_link_down - optional
#   $flush           - optional
#   $zone            - optional
#   $metric          - optional
#   $defroute        - optional
#   $promisc         - optional - defaults to false
#   $restart         - optional - defaults to true
#   $arpcheck        - optional - defaults to true
#
# === Actions:
#
# Performs 'service network restart' after any changes to the ifcfg file and $restart parameter is 'true'.
#
# === TODO:
#
#   HOTPLUG=yes|no
#   WINDOW=
#   SCOPE=
#   SRCADDR=
#   NOZEROCONF=yes
#   PERSISTENT_DHCLIENT=yes|no|1|0
#   DHCPRELEASE=yes|no|1|0
#   DHCLIENT_IGNORE_GATEWAY=yes|no|1|0
#   REORDER_HDR=yes|no
#
# === Authors:
#
# Mike Arnold <mike@razorsedge.org>
#
# === Copyright:
#
# Copyright (C) 2011 Mike Arnold, unless otherwise noted.
#
define network::network_if_base (
  Enum['up', 'down'] $ensure,
  $macaddress,
  $ipaddress       = undef,
  $netmask         = undef,
  Boolean $manage_hwaddr   = true,
  $gateway         = undef,
  Boolean $noaliasrouting  = false,
  $ipv6address     = undef,
  $ipv6gateway     = undef,
  Boolean $ipv6init        = false,
  Boolean $ipv6autoconf    = false,
  $ipv6secondaries = undef,
  $bootproto       = 'none',
  Boolean $userctl         = false,
  $mtu             = undef,
  $dhcp_hostname   = undef,
  $ethtool_opts    = undef,
  $bonding_opts    = undef,
  Boolean $isalias         = false,
  Boolean $peerdns         = false,
  Boolean $ipv6peerdns     = false,
  $dns1            = undef,
  $dns2            = undef,
  $domain          = undef,
  $bridge          = undef,
  $linkdelay       = undef,
  $scope           = undef,
  Boolean $check_link_down = false,
  Boolean $flush           = false,
  $defroute        = undef,
  $zone            = undef,
  $metric          = undef,
  Boolean $promisc         = false,
  Boolean $restart         = true,
  Boolean $arpcheck        = true,
) {

  include '::network'

  $interface = $name

  # Deal with the case where $dns2 is non-empty and $dns1 is empty.
  if $dns2 {
    if !$dns1 {
      $dns1_real = $dns2
      $dns2_real = undef
    } else {
      $dns1_real = $dns1
      $dns2_real = $dns2
    }
  } else {
    $dns1_real = $dns1
    $dns2_real = $dns2
  }

  if $isalias {
    $onparent = $ensure ? {
      'up'    => 'yes',
      'down'  => 'no',
      default => undef,
    }
    $iftemplate = template('network/ifcfg-alias.erb')
  } else {
    $onboot = $ensure ? {
      'up'    => 'yes',
      'down'  => 'no',
      default => undef,
    }
    $iftemplate = template('network/ifcfg-eth.erb')
  }

  if $flush {
    exec { 'network-flush':
      user        => 'root',
      command     => "ip addr flush dev ${interface}",
      refreshonly => true,
      subscribe   => File["ifcfg-${interface}"],
      before      => Service['network'],
      path        => '/sbin:/usr/sbin',
    }
  }

  file { "ifcfg-${interface}":
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    path    => "/etc/sysconfig/network-scripts/ifcfg-${interface}",
    content => $iftemplate,
  }

  if $restart {
    File["ifcfg-${interface}"] {
      notify  => Service['network'],
    }
  }
} # define network::network_if_base
