# puppet-module-fscleanup #
===

Puppet Module to manage cleanup functionality for directories of choice

# Compatability #

This module has been tested to work on the following systems with Puppet v3
(with and without the future parser) and Puppet v4 with Ruby versions 1.8.7,
1.9.3, 2.0.0, 2.1.0 and 2.3.1.

 * OSfamilies running systemd
 * SLED 11
 * SLES 11

On systems running systemd the module will manage settings in /etc/tmpfiles.d/tmp.conf accordingly.

On systems running SLED/SLES 11 the module will apply a workaround to fix a bug in Suses implementation.

The workaround adds these resources:
 * file `/usr/local/etc/fscleanup.conf` - configuration file
 * file `/usr/local/bin/fscleanup.sh` - script containing the workaround
 * file `/etc/init.d/boot.cleanup` - script for cleanup at boot time
 * cron `fscleanup.sh` - cron job to execute the workaround script periodically

Additionally it will remove the old implementation
 * file `/etc/cron.daily/suse.de-clean-tmp` will get removed


# Parameters #

clear_at_boot
-------------
Boolean to choose if directories specified in $tmp_short_dirs should be cleaned up entirely (rm -rf) on bootup.

SLED/SLES 11 specific:
Please note, that this feature ignores $tmp_owners_to_keep - all files will be removed without exception.
This is CLEAR_TMP_DIRS_AT_BOOTUP in fscleanup.conf.

- *Default*: false


ramdisk_cleanup
---------------
Boolean to trigger the ramdisk cleanup functionality. If set to true the script /usr/local/bin/ramdisk_cleanup.sh
will be created/managed and a cron job to run it at 15:30 each day will be added.

- *Default*: false


ramdisk_dir
-----------
String with an absolute path to specify the directory of the ramdisk to cleanup if $ramdisk_cleanup is set to true.

- *Default*: undef


ramdisk_mail
------------
Boolean to choose if deletion announcements should be send out to users 3 days beforehand.

- *Default*: true


ramdisk_max_days
----------------
Integer to choose after how many days files should be removed from $ramdisk_dir.

- *Default*: 21


tmp_cleanup
-----------
Boolean to trigger the tmp dir cleanup functionality. Set this to false if you want to use the ramdisk_cleanup functionality only.
At it's current state the module provide support for SLED/SLES 11 and OSfamilies running systemd only.

- *Default*: true


tmp_long_dirs
-------------
Array with a list of directories, in which old files are to be searched and deleted.

- *Default*: [ '/var/tmp' ]


tmp_long_max_days
-----------------
Integer to define after how many days files will be deleted in $tmp_long_dirs.

- *Default*: 21


tmp_owners_to_keep
------------------
Array with a list of users whose files shall not be deleted.

- *Default*: [ 'root', 'nobody' ]


tmp_short_dirs
--------------
Array with a list of directories, in which old files are to be searched and deleted.

- *Default*: [ '/tmp' ],


tmp_short_max_days
------------------
Integer to define after how many days files will be deleted in $tmp_short_dirs. If set to 0, this feature will be disabled.

- *Default*: 7


# Version history #
0.2.0 2016-11-14
  * add support for systemd
  * refactor of variable validations

0.1.2 2016-02-10
  * use Puppet Fileserver for compatibility reasons
  * fix README.md

0.1.1 2016-02-09
  * serve non-template as file

0.1.0 2016-02-09
  * initial release
