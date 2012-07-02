#!/sbin/sh
# remove_root.sh script written by DRockstar for Team Epic
# version 3 2012-07-03

# designed to remove all known files used in rooting Android devices
# this script can be used from terminal, or  updater-script from recovery
# Copyright (C) 2012 Donovan Bartish

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Busybox location, in this case set by updater-script
BUSYBOX="/tmp/busybox";

# Set the recovery ui progress bar percentage level
# after removing root
ROOT_PROGRESS="0.5";

# Set the recovery ui progress bar percentage level
# after removing busybox
BUSYBOX_PROGRESS="0.8";

# List of root files to remove
# Please feel free to contribute to this list
FILES="
/data/app/com.noshufou.android.su.apk
/data/app/com.noshufou.android.su-1.apk
/data/app/com.noshufou.android.su-2.apk
/data/dalvik-cache/system@app@rootperm.apk@classes.dex
/data/dalvik-cache/system@app@Superuser.apk@classes.dex
/data/data/com.noshufou.android.su
/data/local/root.sh
/data/local/tmp/rageagainstthecage-arm5.bin
/etc/group
/etc/passwd
/etc/resolv.conf
/system/app/rootperm.apk
/system/app/Superuser.apk
/system/bin/jk-su
/system/bin/joeykrim-root.sh
/system/bin/playlogo-orig
/system/bin/remount
/system/bin/resolv.conf
/system/bin/su
/system/etc/resolv.conf
/system/xbin/remount
/system/xbin/su
/system/xbin/keytimer
/data/local/timer_delay
/system/bin/recoveryres
/system/bin/recoveryfiles
";

# List of files to rename to original, each with .bak extension
# Please feel free to contribute to this list
FILES_TO_RENAME="
/system/etc/install-recovery.sh.bak
/system/recovery-from-boot.p.bak
";

# Busybox shortcut variables
CUT="$BUSYBOX cut";
FIND="$BUSYBOX find";
GREP="$BUSYBOX grep";
MOUNT="$BUSYBOX mount";
MV="$BUSYBOX mv -f";
PS="$BUSYBOX ps";
READLINK="$BUSYBOX readlink";
RM="$BUSYBOX rm -rf";
SED="$BUSYBOX sed";
TEST="$BUSYBOX test";

# Get file descriptor for recovery ui output
# Original Credit to Chainfire for recovery ui output script
OUTFD=`$PS | $GREP -v "grep" | $GREP -o -E "update_binary(.*)" | $CUT -d " " -f 3`;

# Emulate set_progress command in updater-script for recovery ui
set_progress() {
  if $TEST "$OUTFD" != ""; then
    echo "set_progress ${1} " 1>&$OUTFD;
  fi;
}

# Emulate ui_print command in updater_script for recovery ui
ui_print() {
  if $TEST "$OUTFD" != ""; then
    echo "ui_print ${1} " 1>&$OUTFD;
    echo "ui_print " 1>&$OUTFD;
  else
    echo "${1}";
  fi;
}

# Remove all root files listed in $FILES
# Rename all files to original names in $FILES_TO_RENAME
remove_root() {
  ui_print "Removing all root files...";
  for ROOTFILE in $FILES; do $RM $ROOTFILE; done;
  ui_print "Renaming .bak files to originals...";
  for FILE in $FILES_TO_RENAME; do
    if $TEST -f $FILE; then
      $MV $FILE `echo $FILE | $SED 's/.bak//'`;
    fi;
  done;
  set_progress $ROOT_PROGRESS;
}

# Remove all busybox installations in /system
remove_busybox() {
  ui_print "Removing busybox installations from /system...";
  for DIR in /system/bin /system/xbin; do
    $RM $DIR/busybox;
    $FIND $DIR -type l | while read line; do
      BUSYBOXTEST=`$READLINK -f $line | $GREP "busybox"`;
      if $TEST "$BUSYBOXTEST" != ""; then
        $RM $line;
        if $TEST -f $BUSYBOXTEST &&\
           $TEST "$BUSYBOXTEST" != "$BUSYBOX" &&\
           $TEST "$BUSYBOXTEST" != "/sbin/busybox"; then
          $RM $BUSYBOXTEST;
        fi;
      fi;
    done;
  done;
  set_progress $BUSYBOX_PROGRESS;
}

ui_print "Mounting /system and /data read/write...";
for MOUNTS in /system /data; do
  $MOUNT -o remount,rw $MOUNTS;
done

case $1 in
"root") remove_root;;
"busybox") remove_busybox;;
*) remove_root; remove_busybox;;
esac;
