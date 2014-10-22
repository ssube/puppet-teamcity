# http://confluence.jetbrains.com/display/TCD8/TeamCity+Specific+Directories#TeamCitySpecificDirectories-tcHomeDir
#
# Database types for 'db_type'
#  - 'postgresql'
#  - 'hsqldb' (default)
class teamcity::server(
  $user            = 'teamcity-server',
  $manage_user     = true,
  $home_dir        = '/opt/teamcity-server',
  $data_dir        = '/var/lib/teamcity-server',
  $log_dir         = '/var/log/teamcity-server',
  $conf_dir        = '/opt/teamcity-server/conf',
  $port            = 8111,
  $server_opts     = '',
  $server_mem_opts = '-Xms1g -Xmx2g -XX:MaxPermSize=270m',
  $db_type         = 'hsqldb',
  $package_name    = 'teamcity-server'
) {
  $service      = 'teamcity-server'
  $bin_dir      = "${home_dir}/bin"
  $temp_dir     = "${home_dir}/temp"
  $catalina_log = "${log_dir}/catalina.log"
  
  anchor { 'teamcity::server::start': }

  # see teamcity-server.erb
  # $catalina_tmp = "$data_dir/temp"
  # $catalina_pid = "/var/run/catalina.pid"

  include teamcity::common

  if $manage_user {
    user { $user:
      ensure => present,
      home   => $home_dir,
      system => true,
    }
  }

  include teamcity::db
  contain teamcity::db

  package { "$package_name":
    ensure  => installed,
  }

  if (($::operatingsystem == "Fedora" and versioncmp($::operatingsystemrelease, '20') >= 0) 
      or ($::operatingsystem == "CentOS" and versioncmp($::operatingsystemmajrelease, '7') >= 0)) {
    $service_file = "/usr/lib/systemd/system/$service.service"
    file { "$service_file":
      ensure  => present,
      content => template('teamcity/teamcity-server-systemd.erb'),
      mode    => '0755',
      require => Anchor['teamcity::server::start'],
      before  => Anchor['teamcity::server::end'],
    }
    
    file { "$home_dir/bin/sys-server.sh":
      ensure  => present,
      content => template('teamcity/sys-server.erb'),
      mode    => '0755',
      require => Anchor['teamcity::server::start'],
      before  => Anchor['teamcity::server::end'],
    }
  } else {
    $service_file = "/etc/init.d/$service"
    file { "$service_file":
      ensure  => present,
      content => template('teamcity/teamcity-server.erb'),
      mode    => '0755',
      require => Anchor['teamcity::server::start'],
      before  => Anchor['teamcity::server::end'],
    }
  }

  contain teamcity::server::config

  service { $service:
    ensure     => running,
    enable     => true,
    hasstatus  => false,
    status     => 'test $(ps -Af | grep teamcity | wc -l) -gt 1',
    hasrestart => true,
    require    => [
      Class['java'],
      Group[$teamcity::common::group],
      Package["$package_name"]
    ],
  }
  
  anchor { 'teamcity::server::end': }
}
