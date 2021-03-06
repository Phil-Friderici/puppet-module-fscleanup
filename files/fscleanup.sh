#!/bin/sh
# This file is being maintained by Puppet.
# DO NOT EDIT

# clean_tmp. This script was split off cron.daily
# Please add your local changes to cron.daily.local
# since this file will be overwritten, when updating your system.
#
# Copyright (c) 1996-2002 SuSE Linux AG, Nuernberg, Germany.
#
# please send bugfixes or comments to http://www.suse.de/feedback.
#
# Author: Burchard Steinbild, 1996
#         Florian La Roche, 1996
#
#
# 2012-10-16 - fscleanup.sh
# Script modified and distributed by eis_fscleanup puppet module
#

#
# paranoia settings
#
umask 022

PATH=/sbin:/bin:/usr/sbin:/usr/bin
export PATH
#
# get information from /etc/sysconfig
#
if [ -f /usr/local/etc/fscleanup.conf ] ; then
    . /usr/local/etc/fscleanup.conf
fi

#
# Delete apropriate files in tmp directories.
#
OMIT=""
for i in $OWNER_TO_KEEP_IN_TMP ; do
    OMIT="$OMIT  ( ! -user $i )"
done

function cleanup_tmp
{
  MAX_DAYS=$1
  shift
  DIRS_TO_CLEAR="$@"

  if [ "$MAX_DAYS" -gt 0 ]; then
    for DIR in $DIRS_TO_CLEAR ; do
      test -x /usr/bin/safe-rm && {
      find $DIR/. $OMIT ! -type d ! -type s ! -type p \
        -atime +$MAX_DAYS -exec /usr/bin/safe-rm {} \;
      } || echo "Error: Can not find /usr/bin/safe-rm"
      find $DIR/. -depth -mindepth 1 $OMIT -type d -empty \
        -mtime +$MAX_DAYS -exec /usr/bin/safe-rmdir {} \;
    done
  fi
}

cleanup_tmp ${MAX_DAYS_IN_TMP:-0} ${TMP_DIRS_TO_CLEAR:-/tmp}
cleanup_tmp ${MAX_DAYS_IN_LONG_TMP:-0} ${LONG_TMP_DIRS_TO_CLEAR}

exit 0
