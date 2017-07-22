#!/bin/sh

## Remove application

sudo /bin/rm -r /Applications/Packages.app

## stop and unload dispatcher

if [ -f /Library/LaunchDaemons/fr.whitebox.packages.build.dispatcher.plist ]; then

	sudo /bin/launchctl unload /Library/LaunchDaemons/fr.whitebox.packages.build.dispatcher.plist

fi

if [ -f /Library/LaunchDaemons/fr.whitebox.packages_dispatcher.plist ]; then

	sudo /bin/launchctl unload /Library/LaunchDaemons/fr.whitebox.packages_dispatcher.plist

fi

## remove launchdaemons

sudo /bin/rm -f /Library/LaunchDaemons/fr.whitebox.packages.build.dispatcher.plist

sudo /bin/rm -f /Library/LaunchDaemons/fr.whitebox.packages_dispatcher.plist

## Remove Priviledged tools

sudo /bin/rm -r /Library/PrivilegedHelperTools/fr.whitebox.packages

## Remove Application Support files

sudo /bin/rm -r /Library/Application\ Support/fr.whitebox.packages

## Remove tools

sudo /bin/rm -f /usr/local/bin/goldin_64
sudo /bin/rm -f /usr/local/bin/goldin
sudo /bin/rm /usr/local/bin/packagesbuild
sudo /bin/rm /usr/local/bin/packagesutil

## Forget we ever got installed

sudo /usr/sbin/pkgutil --forget fr.whitebox.pkg.Packages

exit 0