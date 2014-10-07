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
  ->
  file { ["$home_dir", "$data_dir", "$log_dir"]:
    user    => "$user",
    group   => "$teamcity::common::group",
    mode    => 0755
  }

  class { 'teamcity::server::config':
    content => template('teamcity/teamcity-server.erb'),
    require => Package["$package_name"],
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
}
