class teamcity::server::config(
  $content
) {
  file { ["$teamcity::server::home_dir", "$teamcity::server::log_dir", "$teamcity::server::data_dir"]:
    owner   => $teamcity::server::user,
    group   => $teamcity::common::group,
    mode    => '0755',
    ensure => directory,
  }

  file { "/etc/init.d/$teamcity::server::service":
    ensure  => present,
    content => $content,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    notify  => Service[$teamcity::server::service],
  }
}
