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

/usr/bin/xcodebuild -project "app_packages.xcodeproj" clean build -configuration Release -scheme "app_packages" -derivedDataPath "$ABSOLUTE_BUILD_PATH" CONFIGURATION_BUILD_DIR="$ABSOLUTE_BUILD_PATH"

pushd

## Create the distribution

pushd distribution

/usr/local/bin/packagesbuild -v Packages.pkgproj

pushd

## Create the disk image


exit 0
