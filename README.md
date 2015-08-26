Tweak.prop
==========

About
-----

Tweak.prop is a small yet powerful script to make permanent changes to Android's
`/system/build.prop` more easily or even completely automated.

When upgrading your Android ROM ---which you might do quite frequently when using custom ROMs---,
`/system/build.prop` gets reset to the ROM image's version wiping all your custom changes.

In order to use it your custom settings again, the only way is to reboot, apply your changes and
reboot yet another time for your modified build.prop to take effect.

Tweak.prop gets rid of those annoying behaviour by looking for a file called `tweak.prop` anywhere on
your phone's storage (even external SD card if present) and applies every change you specified. All this
takes place in between updating your ROM and rebooting to *userspace*. This is possible by putting the
tweak.prop script into a flashable zip which can even be flashed automatically by most custom ROMs.

This means, after having set up your personal `tweak.prop` file and eventually putting the `tweakprop.zip`
in some directory on your phone's storage like OpenDelta/FlashAfterUpdate (OmniROM) for example, everytime
you update your ROM `/system/build.prop` will look completely unchanged ---besides date, ROM version, etc.---.
Future changes can easily be made to your `tweak.prop` file using any text editor, terminal emulator, adb or
whatever suits you best.


Usage
-----

See `example.txt` for how to specify certain modifications.

If you're using the git version, simply run `zipit` to create a flashable `tweakprop-${ver}.zip`.

Since user requested it, there is also an *a* version, which already contains a `tweak.prop` file and
therefore won't search your phone for it. Simpy modify `a/tmp/tweak.prop` and run `zipit a` afterwards to
create a flashable `tweakprop-${ver}a.zip`. Besides that, there is no difference between those zip files
and their behaviour.
