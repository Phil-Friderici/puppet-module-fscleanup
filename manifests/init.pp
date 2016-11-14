# == Class: fscleanup
#
# cleanup functionality for directories of choice

class fscleanup (
  $clear_at_boot        = false,
  $ramdisk_cleanup      = false,
  $ramdisk_dir          = undef,
  $ramdisk_mail         = true,
  $ramdisk_max_days     = 21,
  $tmp_cleanup          = true,
  $tmp_long_dirs        = [ '/var/tmp' ],
  $tmp_long_max_days    = 21,
  $tmp_owners_to_keep   = [ 'root', 'nobody' ],
  $tmp_short_dirs       = [ '/tmp' ],
  $tmp_short_max_days   = 7,
) {

  # variable preparations
  $tmp_short_dirs_array = any2array($tmp_short_dirs)
  $tmp_long_dirs_array  = any2array($tmp_long_dirs)
  $clear_at_boot_bool   = str2bool($clear_at_boot)
  $ramdisk_cleanup_bool = str2bool($ramdisk_cleanup)
  $ramdisk_mail_bool    = str2bool($ramdisk_mail)
  $tmp_cleanup_bool     = str2bool($tmp_cleanup)
  $systemd_bool         = str2bool($::systemd)
  $tmp_short_max_days_int = floor($tmp_short_max_days)
  $tmp_long_max_days_int  = floor($tmp_long_max_days)
  $ramdisk_max_days_int   = floor($ramdisk_max_days)

  if is_array($tmp_owners_to_keep) or is_string($tmp_owners_to_keep) {
    $tmp_owners_to_keep_array = any2array($tmp_owners_to_keep)
  }
  else {
    fail('fscleanup::tmp_owners_to_keep is not an array nor a string.')
  }

  # variable validations
  validate_bool(
    $clear_at_boot_bool,
    $tmp_cleanup_bool,
    $ramdisk_cleanup_bool,
    $ramdisk_mail_bool,
  )
  validate_absolute_path(
    $tmp_short_dirs_array,
    $tmp_long_dirs_array,
  )
  validate_integer([
    $tmp_short_max_days_int,
    $tmp_long_max_days_int,
    $ramdisk_max_days_int,
  ])
  validate_array($tmp_owners_to_keep_array)
  if $ramdisk_cleanup_bool == true {
    validate_absolute_path($ramdisk_dir)
  }

  # functionality
  if $tmp_cleanup_bool == true {
    if $systemd_bool == true {
      file { '/etc/tmpfiles.d/tmp.conf' :
        ensure  => 'file',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('fscleanup/tmp.conf.erb'),
      }
    }
    elsif "${::operatingsystem}-${::operatingsystemrelease}" =~ /^(SLED|SLES)-11\.\d/ {
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
        source  => 'puppet:///modules/fscleanup/fscleanup.sh', # lint:ignore:fileserver-check
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
    }
    else {
      fail('fscleanup::tmp_cleanup is only supported on SLED/SLES 11 and OSfamilies using systemd.')
    }
  }

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
      command => "/usr/local/bin/ramdisk_cleanup.sh ${ramdisk_max_days_int} d",
      hour    => '15',
      minute  => '30',
      require => File['/usr/local/bin/ramdisk_cleanup.sh'],
    }
  }
}
