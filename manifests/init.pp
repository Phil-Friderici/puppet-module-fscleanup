# == Class: fscleanup
#
# cleanup functionality for directories of choice

class fscleanup (
  $clear_at_boot        = false,
  $tmp_cleanup          = 'USE_DEFAULTS',
  $tmp_long_dirs        = [ '/var/tmp' ], # need spec tests
  $tmp_long_max_days    = 21,
  $tmp_short_dirs       = [ '/tmp' ],
  $tmp_short_max_days   = 7,
  $tmp_owners_to_keep   = [ 'root', 'nobody' ],
  $ramdisk_cleanup      = false,
  $ramdisk_dir          = undef,
  $ramdisk_mail         = true,
  $ramdisk_max_days     = 21,
) {

  # define OS related defaults
  case $::operatingsystem {
    'SLED', 'SLES': {
      case $::operatingsystemrelease {
        /11\.\d/: {
          $tmp_cleanup_default = true
        }
        default: {
          $tmp_cleanup_default = false
        }
      }
    }
    default: {
      $tmp_cleanup_default = false
    }
  }

  # stringified value conversions (if needed)
  if is_bool($clear_at_boot) == true {
    $clear_at_boot_bool = $clear_at_boot
  } else {
    $clear_at_boot_bool = str2bool($clear_at_boot)
  }

  if is_bool($tmp_cleanup) == true {
    $tmp_cleanup_bool = $tmp_cleanup
  } else {
    $tmp_cleanup_bool = $tmp_cleanup ? {
      'USE_DEFAULTS' => $tmp_cleanup_default,
      default        => str2bool($tmp_cleanup)
    }
  }

  if is_array($tmp_short_dirs) == true {
    $tmp_short_dirs_array = $tmp_short_dirs
  } else {
    $tmp_short_dirs_array = any2array($tmp_short_dirs)
  }

  if is_integer($tmp_short_max_days) == true {
    $tmp_short_max_days_int = $tmp_short_max_days
  } else {
    $tmp_short_max_days_int = floor($tmp_short_max_days)
  }

  if is_array($tmp_owners_to_keep) == true {
    $tmp_owners_to_keep_array = $tmp_owners_to_keep
  } elsif is_string($tmp_owners_to_keep) == true {
    $tmp_owners_to_keep_array = any2array($tmp_owners_to_keep)
  } else {
    fail('fscleanup::tmp_owners_to_keep is not an array nor a string.')
  }

  if is_array($tmp_long_dirs) == true {
    $tmp_long_dirs_array = $tmp_long_dirs
  } else {
    $tmp_long_dirs_array = any2array($tmp_long_dirs)
  }

  if is_integer($tmp_long_max_days) == true {
    $tmp_long_max_days_int = $tmp_long_max_days
  } else {
    $tmp_long_max_days_int = floor($tmp_long_max_days)
  }

  if is_bool($ramdisk_cleanup) == true {
    $ramdisk_cleanup_bool = $ramdisk_cleanup
  } else {
    $ramdisk_cleanup_bool = str2bool($ramdisk_cleanup)
  }

  if is_integer($ramdisk_max_days) == true {
    $ramdisk_max_days_int = $ramdisk_max_days
  } else {
    $ramdisk_max_days_int = floor($ramdisk_max_days)
  }

  if is_bool($ramdisk_mail) == true {
    $ramdisk_mail_bool = $ramdisk_mail
  } else {
    $ramdisk_mail_bool = str2bool($ramdisk_mail)
  }

  # variable validations
  validate_bool($clear_at_boot_bool)
  validate_bool($tmp_cleanup_bool)
  validate_absolute_path($tmp_short_dirs_array)
  validate_integer($tmp_short_max_days_int)
  validate_array($tmp_owners_to_keep_array)
  validate_absolute_path($tmp_long_dirs_array)
  validate_integer($tmp_long_max_days_int)
  validate_bool($ramdisk_cleanup_bool)
  if $ramdisk_cleanup_bool == true {
    validate_absolute_path($ramdisk_dir)
  }
  validate_integer($ramdisk_max_days_int)
  validate_bool($ramdisk_mail_bool)

  # functionality
  if $tmp_cleanup_bool == true {
    if "${::operatingsystem}" !~ /^(SLED|SLES)$/ or "${::operatingsystemrelease}" !~ /^11\./ { # lint:ignore:only_variable_string
      fail('fscleanup::tmp_cleanup is only supported on SLED/SLES 11.')
    }
    else {
      if defined(File['/usr/local/etc']) == false {
        file { '/usr/local/etc' :
          ensure => 'directory',
          owner  => 'root',
          group  => 'root',
          mode   => '0755',
        }
      }

      # template need yes or no
      $clear_at_boot_string = bool2str($clear_at_boot_bool, 'yes', 'no')

      file { '/usr/local/etc/fscleanup.conf' :
        ensure  => 'file',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('fscleanup/fscleanup.conf.erb'),
        require => File['/usr/local/etc'],
      }

      file { '/usr/local/bin/fscleanup.sh' :
        ensure  => 'file',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template('fscleanup/fscleanup.sh.erb'),
        require => File['/usr/local/etc/fscleanup.conf'],
      }

      file { '/etc/cron.daily/suse.de-clean-tmp' :
        ensure => 'absent',
      }

      cron { 'fscleanup.sh' :
        command => '/usr/local/bin/fscleanup.sh >/dev/null 2>&1',
        hour    => '06',
        minute  => '00',
        require => File['/usr/local/bin/fscleanup.sh'],
      }

      file { '/etc/init.d/boot.cleanup' :
        ensure  => 'file',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template('fscleanup/boot.cleanup.erb'),
      }
    } # else
  } # if $cleanip_dirs_bool

  if $ramdisk_cleanup == true {
    file { '/usr/local/bin/ramdisk_cleanup.sh' :
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => template('fscleanup/ramdisk_cleanup.sh.erb'),
    }

    # If mail should be sent out, this can only run once a day!
    cron { 'ramdisk_cleanup.sh' :
      command => "/usr/local/bin/ramdisk_cleanup.sh ${ramdisk_max_days} d",
      hour    => '15',
      minute  => '30',
      require => File['/usr/local/bin/ramdisk_cleanup.sh'],
    }
  }
}
