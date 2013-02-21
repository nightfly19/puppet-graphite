class graphite (
  $manage_user         = false,
  $manage_home         = false,
  $home                = "/opt/graphite",
  $user                = "graphite",
  $password            = '*',
  $whisper_source      = "https://github.com/graphite-project/whisper",
  $carbon_source       = "https://github.com/graphite-project/carbon.git",
  $graphite_web_source = "https://github.com/graphite-project/graphite-web.git",
  $version = "0.9.10"
) {

  $repo_home      = "${graphite::home}/.repos"
  $repo_whisper   = "${graphite::home}/.repos/whisper"
  $repo_carbon    = "${graphite::home}/.repos/carbon"
  $repo_graphite  = "${graphite::home}/.repos/graphite_web"

  if $graphite::manage_user {
    group{$graphite::user:
      ensure => present,
    }
    
    user{$graphite::user:
      ensure  => present,
      home    => $graphite::home,
      gid     => $graphite::user,
      require => Group[$graphite::user],
    }
  }

  if $graphite::manage_home {
    file{$graphite::home:
      ensure => directory,
      owner  => $graphite::user,
    }
  }

  package{'python-twisted':
    ensure => installed,
  }
  
  File{
    owner => $graphite::user,
    group => $graphite::user,
    mode  => '0744',
  }
    
  file{$repo_home:
    ensure => directory,
  }
  
  file{"${repo_carbon}/setup.cfg":
    ensure   => present,
    content  => template('graphite/carbon_install_cfg.erb'),
    require  => Vcsrepo[$repo_carbon],
    notify   => Exec['install-carbon'],
  }
  
  exec{'install-whisper':
    provider    => 'shell',
    command     => 'python ./setup.py install',
    cwd         => $repo_whisper,
    path        => ['/bin/', '/usr/bin','/usr/local/bin'],
    refreshonly => true,
  }

  exec{'install-carbon':
    provider    => 'shell',
    command     => "python ./setup.py install && \
    chown -R ${graphite::user}:${graphite::user} ${graphite::home}/storage",
    cwd         => $repo_carbon,
    path        => ['/bin/', '/usr/bin','/usr/local/bin'],
    refreshonly => true,
  }
  
  vcsrepo{$repo_whisper:
    ensure   => 'present',
    provider => 'git',
    source   => $whisper_source,
    user     => $graphite::user,
    revision => $version,
    require  => File[$repo_home],
    notify   => Exec['install-whisper'],
  }

  vcsrepo{$repo_carbon:
    ensure   => 'present',
    provider => 'git',
    source   => $carbon_source,
    user     => $graphite::user,
    revision => $version,
    require  => File[$repo_home],
  }

  vcsrepo{$repo_graphite:
    ensure   => 'present',
    provider => 'git',
    source   => $graphite_web_source,
    user     => $graphite::user,
    revision => $version,
    require  => File[$repo_home],
  }

}
