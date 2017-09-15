#!/sbin/sh
set -e

ver=0.6.0


# ui_print - QuixoticNerd - works with both TWRP & CM

# Get the parent process file descriptor
# it's the second argument
OUTFD=$( xargs -0 < /proc/${PPID}/cmdline | awk '{print $3}' ) 2>/dev/null
echo "${OUTFD}"
# If exists then use it - otherwise echo
# the log file should capture echos
ui_print() {
    if [ "${OUTFD}" != "" ]; then
        echo "ui_print ${1} " 1>&/proc/self/fd/$OUTFD;
    else
        echo "${1}";
    fi;
}

ui_print " "
ui_print "##############################"
ui_print "#       tweakprop $ver      #"
ui_print "#         --by kl3--         #"
ui_print "#   --modified by ferstar--  #"
ui_print "##############################"
ui_print " "

ex() {
    ui_print "ERROR: $@, script aborted!"
    exit 1
}
bak=/sdcard/build.prop.origin
build=/system/build.prop

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

if [ -f "${bak}" ]; then
    mv "${bak}" "${build}"
    ui_print "build.prop restored, you can use OTA properly."
    exit 0
else
    cp "${build}" "${bak}"
    ui_print "Copy ${build} to ${bak}..."
    ui_print "Don't modify or delete it"
fi

ui_print "Set write permissions for $build..."
chmod 0666 $build
echo "" >> $build

tweak="/tmp/tweak.prop"

## abort execution if file is not found or empty
if test -s "$tweak"; then
    ui_print "..$tweak found and not empty"
else
    ui_print "ERROR: Personal file $name not found or empty, script aborted!"
    chmod 0644 "$build" && ui_print "..original permissions for $build restored"
    exit 1
fi

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
