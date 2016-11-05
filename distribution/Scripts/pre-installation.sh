#!/bin/sh

if [ -f /Library/LaunchDaemons/fr.whitebox.packages.build.dispatcher.plist ]; then

	/bin/launchctl unload /Library/LaunchDaemons/fr.whitebox.packages.build.dispatcher.plist

fi

if [ -f /Library/LaunchDaemons/fr.whitebox.packages_dispatcher.plist ]; then

	/bin/launchctl unload /Library/LaunchDaemons/fr.whitebox.packages_dispatcher.plist

fi

exit 0
