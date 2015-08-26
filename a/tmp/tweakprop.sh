#!/sbin/sh
set -e
## /tmp/tweakprop.sh | tweakprop http://forum.xda-developers.com/showthread.php?t=2664332 | https://notabug.org/kl3/tweakprop
ver=0.5.9a

## credits for ui_print() go to chainfire
OUTFD=$2
ui_print() {
	echo -n -e "ui_print $1\n" > /proc/self/fd/$OUTFD
	echo -n -e "ui_print\n" > /proc/self/fd/$OUTFD
}

ui_print " "
ui_print "###############################"
ui_print "#       tweakprop $ver       #"
ui_print "#         --by kl3--          #"
ui_print "###############################"
ui_print " "

ex() {
	ui_print "ERROR: $@, script aborted!"
	exit 1
}

build=/system/build.prop
echo "" >> $build



for part in system data
do
	ui_print "Mount /$part partition..."
	if mount | grep -q "/$part"
	then
		mount -o rw,remount "/$part" "/$part" && ui_print "/$part remounted rw" || ex "Cannot get write acces on /$part"
	else
		mount -o rw "/$part" && ui_print "/$part mounted rw" || ex "/$part cannot mounted"
	fi
done

ui_print "Set write permissions for $build..."
chmod 0666 $build



tweak="/tmp/tweak.prop"

## abort execution if file is not found or empty
test -s "$tweak" && ui_print "..$tweak found and not empty" || (ui_print "ERROR: Personal file $name not found or empty, script aborted!"; exit 1)

## check if original $build should be backed up
answer=$(sed "s/BACKUP=//p;d" "$tweak")

backup() {
	## create backup file containing date and used tweakprop version
	## if valid and writeable
	echo "# Backup of $build created at `date` using tweakprop version $ver" > "$1" || ex "Cannot write to backup file $1" && \
	(cat "$build" >> "$1" && ui_print "..$build backed up at $1.")
}

case "$answer" in
y|Y|yes|Yes|YES)
	## use same directory where tweak.prop was found
	backup "${tweak%/*}/${build##*/}.backup"
	;;

n|N|no|No|NO)
	;;

*)
	## check if empty or invalid
	[[ -z "$answer" || ! -d $(dirname "$answer") ]] && ex "Given path is empty or parent directory does not exist" || backup "$answer"
	;;
esac

ui_print "scanning $tweak..."
ui_print ""

## read only lines matching valid entry pattern (someVAR=someVAL, !someSTR, @someENTR|someSTR, $someVAR=someVAL)
sed -r '/(^#|^ *$|^BACKUP=)/d;/(.*=.*|^\!|^\@.*\|.*|^\$.*\|.*)/!d' "$tweak" | while read line
do
	## remove entry
	if echo "$line" | grep -q '^\!'
	then
		entry=$(echo "${line#?}" | sed -e 's/[\/&]/\\&/g')
		## remove from $build if present
		grep -q "$entry" "$build" && (sed "/$entry/d" -i "$build" && ui_print "..all lines containing \"$entry\" removed")

	## append string
	elif echo "$line" | grep -q '^\@'
	then
		entry=$(echo "${line#?}" | sed -e 's/[\/&]/\\&/g')
		var=$(echo "$entry" | cut -d\| -f1)
		app=$(echo "$entry" | cut -d\| -f2)
		## append string to $var's value if present in $build
		grep -q "$var" "$build" && (sed "s/^$var=.*$/&$app/" -i "$build" && ui_print "..\"$app\" appended to value of \"$var\"")

	## change value only iif entry exists
	elif echo "$line" | grep -q '^\$'
	then
		entry=$(echo "${line#?}" | sed -e 's/[\/&]/\\&/g')
		var=$(echo "$entry" | cut -d\| -f1)
		new=$(echo "$entry" | cut -d\| -f2)
		## change $var's value iif $var present in $build
		grep -q "$var=" "$build" && (sed "s/^$var=.*$/$var=$new/" -i "$build" && ui_print "..value of \"$var\" changed to \"$new\"")

	## add or override entry
	else
		var=$(echo "$line" | cut -d= -f1)
		## if variable already present in $build
		if grep -q "$var" "$build"
		then
			## override value in $build if different
			grep -q $(grep "$var" "$tweak") "$build" || (sed "s/^$var=.*$/$line/" -i "$build" && ui_print "..value of \"$var\" overridden")
		## else append entry to $build
		else
			echo "$line" >> "$build" && ui_print "..entry \"$line\" added"
		fi
	fi
done

## trim empty and duplicate lines of $build
sed '/^ *$/d' -i "$build"

ui_print " "
ui_print "Tweaks successfully applied!"

chmod 0644 "$build" && ui_print "..original permissions for $build restored"

for part in system data
do
	umount "/$part" && ui_print "../$part unmounted"
done

ui_print "Script finished!"
