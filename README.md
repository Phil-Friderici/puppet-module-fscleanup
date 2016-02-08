# puppet-module-fscleanup #
===

Puppet Module to manage cleanup functionality for directories of choice

# Compatability #

This module has been tested to work on the following systems with Puppet v3
(with and without the future parser) and Puppet v4 with Ruby versions 1.8.7,
1.9.3, 2.0.0 and 2.1.0.

 * SLED 11
 * SLES 11


This module provides OS default values for these OSfamilies:

 * SLED 11
 * SLES 11

# Version history #
0.0.1 2016-02-08 initial release


# Parameters #

clear_at_boot
-------------
Boolean to choose if directories specified in $tmp_short_dirs should be cleaned up entirely (rm -rf) on bootup.
Please note, that this feature ignores $tmp_owners_to_keep - all files will be removed without exception.
This is CLEAR_TMP_DIRS_AT_BOOTUP in fscleanup.conf.

- *Default*: false


ramdisk_cleanup
---------------
Boolean to trigger the ramdisk cleanup functionality.

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
Boolean to trigger the tmp dir cleanup functionality. 'USE_DEFAULTS' will activate the functionality only for SLED/SLES 11.
tmp_cleanup is only supported on SLED/SLES 11 systems at the moment. Set this to false if you want to use the ramdisk_cleanup functionality only.

- *Default*: 'USE_DEFAULTS'


tmp_long_dirs
-------------
Array with a list of directories, in which old files are to be searched and deleted.
This is LONG_TMP_DIRS_TO_CLEAR in fscleanup.conf.

- *Default*: [ '/var/tmp' ]


tmp_long_max_days
-----------------
Integer to define after how many days file will be deleted in $tmp_long_dirs. If set to 0, this feature will be disabled.
This is MAX_DAYS_IN_LONG_TMP in fscleanup.conf.

- *Default*: 21


tmp_owners_to_keep
------------------
Array with a list of users whose files shall not be deleted.
This is OWNER_TO_KEEP_IN_TMP in fscleanup.conf.

- *Default*: [ 'root', 'nobody' ]


tmp_short_dirs
--------------
Array with a list of directories, in which old files are to be searched and deleted.
This is TMP_DIRS_TO_CLEAR in fscleanup.conf.

- *Default*: [ '/tmp' ],


tmp_short_max_days
------------------
Integer to define after how many days file will be deleted in $tmp_long_dirs. If set to 0, this feature will be disabled.
This is MAX_DAYS_IN_TMP in fscleanup.conf.

- *Default*: 7
