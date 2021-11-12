#!/bin/sh

BASEDIR="$( dirname "$0" )"
cd "$BASEDIR"

ABSOLUTE_FOLDER_PATH=`pwd`
ABSOLUTE_BUILD_PATH="$ABSOLUTE_FOLDER_PATH"/distribution/build

echo "$ABSOLUTE_FOLDER_PATH"

## Create the build folder if needed

/bin/mkdir -p distribution/build

## Create the artifacts folder if needed

/bin/mkdir -p distribution/artifacts

# Retrieve the version

VERSION="1.0"

if [ -f distribution/Version ];
then

	VERSION=`cat distribution/Version`

fi

# Get the current year

CURRENT_YEAR=`date "+%Y"`

## Build goldin

pushd goldin

/usr/bin/xcodebuild clean build -configuration Release -scheme "goldin" -derivedDataPath "$ABSOLUTE_BUILD_PATH" CONFIGURATION_BUILD_DIR="$ABSOLUTE_BUILD_PATH"

popd

## Build packagesutil 

pushd packagesutil

/usr/bin/xcodebuild clean build -configuration Release -scheme "packagesutil" -derivedDataPath "$ABSOLUTE_BUILD_PATH" CONFIGURATION_BUILD_DIR="$ABSOLUTE_BUILD_PATH"

popd

## Build packagesbuild

pushd packagesbuild

/usr/bin/xcodebuild clean build -configuration Release -scheme "packagesbuild" -derivedDataPath "$ABSOLUTE_BUILD_PATH" CONFIGURATION_BUILD_DIR="$ABSOLUTE_BUILD_PATH"

popd

## Build packages_dispatcher

pushd packages_dispatcher

/usr/bin/xcodebuild clean build -configuration Release -scheme "packages_dispatcher" -derivedDataPath "$ABSOLUTE_BUILD_PATH" CONFIGURATION_BUILD_DIR="$ABSOLUTE_BUILD_PATH"

popd

## Build packages_builder

pushd packages_builder

/usr/bin/xcrun agvtool next-version -all

/usr/bin/xcodebuild clean build -configuration Release -scheme "packages_builder" -derivedDataPath "$ABSOLUTE_BUILD_PATH" CONFIGURATION_BUILD_DIR="$ABSOLUTE_BUILD_PATH"

pushd


## Build the plugins

pushd plugins/requirements

requirements_plugins_list=("CPU" "DiskSpace" "Files" "JavaScript" "OS" "RAM" "Script")

for requirement_plugin in "${requirements_plugins_list[@]}"
do

	pushd $requirement_plugin

	/usr/bin/xcodebuild clean build -configuration Release -scheme "$requirement_plugin" -derivedDataPath "$ABSOLUTE_BUILD_PATH/requirements" CONFIGURATION_BUILD_DIR="$ABSOLUTE_BUILD_PATH/requirements"

	popd

done

popd

pushd plugins/locators

locators_plugins_list=("JavaScript" "Standard")

for locator_plugin in "${locators_plugins_list[@]}"
do

	pushd $locator_plugin

	/usr/bin/xcodebuild clean build -configuration Release -scheme "$locator_plugin" -derivedDataPath "$ABSOLUTE_BUILD_PATH/locators" CONFIGURATION_BUILD_DIR="$ABSOLUTE_BUILD_PATH/locators"

	popd

done

popd


## Build the application

pushd app_packages

/usr/bin/xcrun agvtool next-version -all

/usr/bin/xcrun agvtool new-marketing-version $VERSION

/usr/bin/xcodebuild -project "app_packages.xcodeproj" clean build -configuration Release -scheme "app_packages" -derivedDataPath "$ABSOLUTE_BUILD_PATH" CONFIGURATION_BUILD_DIR="$ABSOLUTE_BUILD_PATH"

popd

## Create the distribution

pushd distribution

/usr/local/bin/packagesbuild --verbose --project Packages.pkgproj DISTRIBUTION_PRODUCT_VERSION="${VERSION}" COPYRIGHT_END_YEAR="${CURRENT_YEAR}"

## Create the disk image

DISKIMAGE_NAME="Packages"

## Convert disk image template to read-write disk image

if [ -f build/"$DISKIMAGE_NAME"_rw.dmg ]
then 
	/bin/rm build/"$DISKIMAGE_NAME"_rw.dmg
fi

/usr/bin/hdiutil convert Template/Template_ro.dmg -format UDRW -o build/"$DISKIMAGE_NAME"_rw.dmg > /dev/null

## Mount the disk image

/usr/bin/hdiutil attach build/"$DISKIMAGE_NAME"_rw.dmg -mountpoint build/diskimage_rw > /dev/null

## Rename the disk image

if [ -f Version ];
then

	/usr/sbin/diskutil rename "$DISKIMAGE_NAME" "$DISKIMAGE_NAME $VERSION" 
fi

## Copy the Read Before You Install Packages to the disk image and prevent edition

if [ -f "Documents/Read Before You Install Packages.rtf" ]
then

	/usr/bin/sed '2 s/^/\\readonlydoc1/' <"Documents/Read Before You Install Packages.rtf" > "build/diskimage_rw/Read Before You Install Packages.rtf"

else

	echo "Missing Read Before You Install Packages"
fi

## Copy the User Guide webloc

if [ -f "Documents/Packages User Guide.webloc" ]
then

	/bin/cp "Documents/Packages User Guide.webloc" "build/diskimage_rw/Extras/Packages User Guide.webloc"

else

	echo "Missing Packages User Guide.webloc"
fi

## Copy the uninstall.sh script

if [ -f "Scripts/uninstall.sh" ]
then

	/bin/cp Scripts/uninstall.sh "build/diskimage_rw/Extras/uninstall.sh"

else

	echo "Missing uninstall.sh"
fi

## Copy the distribution package to the disk image

if [ -f build/Packages.pkg ]
then

	/bin/cp build/Packages.pkg build/diskimage_rw/packages/Packages.pkg

else

	echo "Missing distribution packages"
fi

## Remove useless files for a disk image

/bin/rm "build/diskimage_rw/Desktop DB"
/bin/rm "build/diskimage_rw/Desktop DF"
/bin/rm -r build/diskimage_rw/.fseventsd

## Unmount the disk image

/usr/bin/hdiutil detach build/diskimage_rw > /dev/null

## Convert disk image to read-only

if [ -f artifacts/"$DISKIMAGE_NAME".dmg ]
then 
	/bin/rm artifacts/"$DISKIMAGE_NAME".dmg
fi

/usr/bin/hdiutil convert build/"$DISKIMAGE_NAME"_rw.dmg -format UDZO -o artifacts/"$DISKIMAGE_NAME".dmg > /dev/null

## Remove the temporary disk image

if [ -f build/"$DISKIMAGE_NAME"_rw.dmg ]
then 
	/bin/rm build/"$DISKIMAGE_NAME"_rw.dmg
fi

popd

exit 0
