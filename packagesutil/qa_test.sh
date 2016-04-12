#!/bin/sh

BASEDIR="$( dirname "$0" )"
cd "$BASEDIR"

ABSOLUTE_FOLDER_PATH=`pwd`
ABSOLUTE_BUILD_PATH="$ABSOLUTE_FOLDER_PATH"/build/Release

PROJECT_FOLDER="packagesutil"
SCHEME_NAME="packagesutil"

## Create the build folder if needed

/bin/mkdir -p build/Release

/usr/bin/xcodebuild clean build -configuration Release -scheme "$SCHEME_NAME" -derivedDataPath "$ABSOLUTE_BUILD_PATH" CONFIGURATION_BUILD_DIR="$ABSOLUTE_BUILD_PATH" >> /dev/null

cd build/Release

echo "------ Missing file argument ------"

./packagesutil get project name


echo "------ Missing file argument value ------"

./packagesutil get project name --file 


echo "------ Get Project Name ------"

 # Distribution

./packagesutil get project name --file ../../tests/test.distribution.pkgproj

 # Raw Package

./packagesutil get project name --file ../../tests/test.raw.package.pkgproj


echo "------ Set Project Name ------"

 # Distribution

./packagesutil set project name "toto.distribution" --file ../../tests/test.distribution.pkgproj

./packagesutil get project name --file ../../tests/test.distribution.pkgproj

./packagesutil set project name "test.distribution" --file ../../tests/test.distribution.pkgproj

 # Raw Package

./packagesutil set project name "toto.package" --file ../../tests/test.raw.package.pkgproj

./packagesutil get project name --file ../../tests/test.raw.package.pkgproj

./packagesutil set project name "test.raw.package" --file ../../tests/test.raw.package.pkgproj


echo "------ Get Project Build Format ------"

 # Distribution

./packagesutil get project build-format --file ../../tests/test.distribution.pkgproj

 # Raw Package (Should return flat)

./packagesutil get project build-format --file ../../tests/test.raw.package.pkgproj


echo "------ Set Project Build Format ------"

## Set Project Build Format

 # Distribution

./packagesutil set project build-format flat --file ../../tests/test.distribution.pkgproj

./packagesutil get project build-format --file ../../tests/test.distribution.pkgproj

./packagesutil set project build-format bundle --file ../../tests/test.distribution.pkgproj

./packagesutil get project build-format --file ../../tests/test.distribution.pkgproj

# Distrbution (invalid value - should fail)

./packagesutil set project build-format house --file ../../tests/test.distribution.pkgproj

 # Raw Package (Should fail)

./packagesutil set project build-format flat --file ../../tests/test.raw.package.pkgproj


echo "------ Get Package Name ------"

 # Distribution Standard Index

./packagesutil get package-1 name --file ../../tests/test.distribution.pkgproj

 # Distribution Standard Identifier

./packagesutil get package com.mycompanyname.pkg.test.distribution name --file ../../tests/test.distribution.pkgproj

 # Distribution Reference

./packagesutil get package-1 name --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported

./packagesutil get package-1 name --file ../../tests/test.distribution.imported.pkgproj

 # Distribution Missing Index/Identifier (should fail)

./packagesutil get package-2 name --file ../../tests/test.distribution.pkgproj

./packagesutil get package mycompanyname.pkg.test.distribution name --file ../../tests/test.distribution.pkgproj

 # Package (should fail)

./packagesutil get name --file ../../tests/test.raw.package.pkgproj


echo "------ Set Package Name ------"

# Distribution Standard

./packagesutil set package-1 name "toto.package" --file ../../tests/test.distribution.pkgproj

./packagesutil get package-1 name --file ../../tests/test.distribution.pkgproj

./packagesutil set package-1 name "test.distribution" --file ../../tests/test.distribution.pkgproj

 # Distribution Reference

./packagesutil set package-1 name "toto.package" --file ../../tests/test.distribution.reference.pkgproj

./packagesutil get package-1 name --file ../../tests/test.distribution.reference.pkgproj

./packagesutil set package-1 name "untitled package" --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported (should fail)

./packagesutil set package-1 name "toto.package" --file ../../tests/test.distribution.imported.pkgproj

# Empty name (should fail)

./packagesutil set package-1 name "" --file ../../tests/test.distribution.pkgproj

 # Package (should fail)

./packagesutil set name "toto.package" --file ../../tests/test.raw.package.pkgproj


echo "------ Get Package Identifier ------"

 # Distribution Standard

./packagesutil get package-1 identifier --file ../../tests/test.distribution.pkgproj

 # Distribution Reference

./packagesutil get package-1 identifier --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported

./packagesutil get package-1 identifier --file ../../tests/test.distribution.imported.pkgproj

 # Package

./packagesutil get identifier --file ../../tests/test.raw.package.pkgproj


echo "------ Set Package Identifier ------"

 # Distribution Standard Index

./packagesutil set package-1 identifier "toto.identifier" --file ../../tests/test.distribution.pkgproj

./packagesutil get package-1 identifier --file ../../tests/test.distribution.pkgproj

./packagesutil set package-1 identifier "com.mycompanyname.pkg.test.distribution" --file ../../tests/test.distribution.pkgproj

 # Distribution Reference

./packagesutil set package-1 identifier "toto.identifier" --file ../../tests/test.distribution.reference.pkgproj

./packagesutil get package-1 identifier --file ../../tests/test.distribution.reference.pkgproj

./packagesutil set package-1 identifier "com.mycompanyname.pkg.untitled_package" --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported (should fail)

./packagesutil set package-1 identifier "toto.identifier" --file ../../tests/test.distribution.imported.pkgproj

 # Package

./packagesutil set identifier "toto.identifier" --file ../../tests/test.raw.package.pkgproj

./packagesutil get identifier --file ../../tests/test.raw.package.pkgproj

./packagesutil set identifier "com.mycompanyname.pkg.test.raw.package" --file ../../tests/test.raw.package.pkgproj


echo "------ Get Package Version ------"

 # Distribution Standard

./packagesutil get package-1 version --file ../../tests/test.distribution.pkgproj

 # Distribution Reference

./packagesutil get package-1 version --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported

./packagesutil get package-1 version --file ../../tests/test.distribution.imported.pkgproj

 # Package

./packagesutil get version --file ../../tests/test.raw.package.pkgproj


echo "------ Set Package Version ------"

 # Distribution Standard

./packagesutil set package-1 version "1.1" --file ../../tests/test.distribution.pkgproj

./packagesutil get package-1 version --file ../../tests/test.distribution.pkgproj

./packagesutil set package-1 version "1.0" --file ../../tests/test.distribution.pkgproj

 # Distribution Reference

./packagesutil set package-1 version "1.1" --file ../../tests/test.distribution.reference.pkgproj

./packagesutil get package-1 version --file ../../tests/test.distribution.reference.pkgproj

./packagesutil set package-1 version "1.0" --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported (should fail)

./packagesutil set package-1 version "1.1" --file ../../tests/test.distribution.imported.pkgproj

# Empty version (should fail)

./packagesutil set package-1 version "" --file ../../tests/test.distribution.pkgproj

 # Package

./packagesutil set version "1.1" --file ../../tests/test.raw.package.pkgproj

./packagesutil get version --file ../../tests/test.raw.package.pkgproj

./packagesutil set version "1.0" --file ../../tests/test.raw.package.pkgproj


echo "------ Get Package Post-Installation Behavior ------"

 # Distribution Standard

./packagesutil get package-1 post-installation-behavior --file ../../tests/test.distribution.pkgproj

 # Distribution Reference

./packagesutil get package-1 post-installation-behavior --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported

./packagesutil get package-1 post-installation-behavior --file ../../tests/test.distribution.imported.pkgproj

 # Package

./packagesutil get post-installation-behavior --file ../../tests/test.raw.package.pkgproj


echo "------ Set Package Post-Installation Behavior ------"

 # Distribution Standard

./packagesutil set package-1 post-installation-behavior require-restart --file ../../tests/test.distribution.pkgproj

./packagesutil get package-1 post-installation-behavior --file ../../tests/test.distribution.pkgproj

./packagesutil set package-1 post-installation-behavior require-shutdown --file ../../tests/test.distribution.pkgproj

./packagesutil get package-1 post-installation-behavior --file ../../tests/test.distribution.pkgproj

./packagesutil set package-1 post-installation-behavior require-logout --file ../../tests/test.distribution.pkgproj

./packagesutil get package-1 post-installation-behavior --file ../../tests/test.distribution.pkgproj

./packagesutil set package-1 post-installation-behavior require-error --file ../../tests/test.distribution.pkgproj

./packagesutil set package-1 post-installation-behavior do-nothing --file ../../tests/test.distribution.pkgproj

 # Distribution Reference

./packagesutil set package-1 post-installation-behavior require-restart --file ../../tests/test.distribution.reference.pkgproj

./packagesutil get package-1 post-installation-behavior --file ../../tests/test.distribution.reference.pkgproj

./packagesutil set package-1 post-installation-behavior do-nothing --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported (should fail)

./packagesutil set package-1 post-installation-behavior require-restart --file ../../tests/test.distribution.imported.pkgproj

 # Package

./packagesutil set post-installation-behavior require-restart --file ../../tests/test.raw.package.pkgproj

./packagesutil get post-installation-behavior --file ../../tests/test.raw.package.pkgproj

./packagesutil set post-installation-behavior do-nothing --file ../../tests/test.raw.package.pkgproj


echo "------ Get Require Admin Password ------"

 # Distribution Standard

./packagesutil get package-1 require-admin-password --file ../../tests/test.distribution.pkgproj

 # Distribution Reference

./packagesutil get package-1 require-admin-password --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported

./packagesutil get package-1 require-admin-password --file ../../tests/test.distribution.imported.pkgproj

 # Package

./packagesutil get require-admin-password --file ../../tests/test.raw.package.pkgproj


echo "------ Set Require Admin Password ------"

 # Distribution Standard

./packagesutil set package-1 require-admin-password no --file ../../tests/test.distribution.pkgproj

./packagesutil get package-1 require-admin-password --file ../../tests/test.distribution.pkgproj

./packagesutil set package-1 require-admin-password yes --file ../../tests/test.distribution.pkgproj

 # Distribution Reference

./packagesutil set package-1 require-admin-password no --file ../../tests/test.distribution.reference.pkgproj

./packagesutil get package-1 require-admin-password --file ../../tests/test.distribution.reference.pkgproj

./packagesutil set package-1 require-admin-password yes --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported (should fail)

./packagesutil set package-1 require-admin-password no --file ../../tests/test.distribution.imported.pkgproj

 # Package

./packagesutil set require-admin-password no --file ../../tests/test.raw.package.pkgproj

./packagesutil get require-admin-password --file ../../tests/test.raw.package.pkgproj

./packagesutil set require-admin-password yes --file ../../tests/test.raw.package.pkgproj

echo "------ Get Location Type ------"

 # Distribution Standard

./packagesutil get package-1 location-type --file ../../tests/test.distribution.pkgproj

 # Distribution Reference (should fail)

./packagesutil get package-1 location-type --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported

./packagesutil get package-1 location-type --file ../../tests/test.distribution.imported.pkgproj

 # Package

./packagesutil get location-type --file ../../tests/test.raw.package.pkgproj





echo "------ Get Relocatable ------"

 # Distribution Standard

./packagesutil get package-1 relocatable --file ../../tests/test.distribution.pkgproj

 # Distribution Reference (should fail)

./packagesutil get package-1 relocatable --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported

./packagesutil get package-1 relocatable --file ../../tests/test.distribution.imported.pkgproj

 # Package

./packagesutil get relocatable --file ../../tests/test.raw.package.pkgproj


echo "------ Set Relocatable ------"

 # Distribution Standard

./packagesutil set package-1 relocatable yes --file ../../tests/test.distribution.pkgproj

./packagesutil get package-1 relocatable --file ../../tests/test.distribution.pkgproj

./packagesutil set package-1 relocatable no --file ../../tests/test.distribution.pkgproj

 # Distribution Reference (should fail)

./packagesutil set package-1 relocatable yes --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported (should fail)

./packagesutil set package-1 relocatable yes --file ../../tests/test.distribution.imported.pkgproj

 # Package

./packagesutil set relocatable yes --file ../../tests/test.raw.package.pkgproj

./packagesutil get relocatable --file ../../tests/test.raw.package.pkgproj

./packagesutil set relocatable no --file ../../tests/test.raw.package.pkgproj


echo "------ Get Overwrite Directory Permission ------"

 # Distribution Standard

./packagesutil get package-1 overwrite-directory-permission --file ../../tests/test.distribution.pkgproj

 # Distribution Reference (should fail)

./packagesutil get package-1 overwrite-directory-permission --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported

./packagesutil get package-1 overwrite-directory-permission --file ../../tests/test.distribution.imported.pkgproj

 # Package

./packagesutil get overwrite-directory-permission --file ../../tests/test.raw.package.pkgproj


echo "------ Set Overwrite Directory Permission ------"

 # Distribution Standard

./packagesutil set package-1 overwrite-directory-permission yes --file ../../tests/test.distribution.pkgproj

./packagesutil get package-1 overwrite-directory-permission --file ../../tests/test.distribution.pkgproj

./packagesutil set package-1 overwrite-directory-permission no --file ../../tests/test.distribution.pkgproj

 # Distribution Reference (should fail)

./packagesutil set package-1 overwrite-directory-permission yes --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported (should fail)

./packagesutil set package-1 overwrite-directory-permission yes --file ../../tests/test.distribution.imported.pkgproj

 # Package

./packagesutil set overwrite-directory-permission yes --file ../../tests/test.raw.package.pkgproj

./packagesutil get overwrite-directory-permission --file ../../tests/test.raw.package.pkgproj

./packagesutil set overwrite-directory-permission no --file ../../tests/test.raw.package.pkgproj


echo "------ Get Follow Symbolic Links ------"

 # Distribution Standard

./packagesutil get package-1 follow-symbolic-links --file ../../tests/test.distribution.pkgproj

 # Distribution Reference (should fail)

./packagesutil get package-1 follow-symbolic-links --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported

./packagesutil get package-1 follow-symbolic-links --file ../../tests/test.distribution.imported.pkgproj

 # Package

./packagesutil get follow-symbolic-links --file ../../tests/test.raw.package.pkgproj


echo "------ Set Follow Symbolic Links ------"

 # Distribution Standard

./packagesutil set package-1 follow-symbolic-links yes --file ../../tests/test.distribution.pkgproj

./packagesutil get package-1 follow-symbolic-links --file ../../tests/test.distribution.pkgproj

./packagesutil set package-1 follow-symbolic-links no --file ../../tests/test.distribution.pkgproj

 # Distribution Reference (should fail)

./packagesutil set package-1 follow-symbolic-links yes --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported (should fail)

./packagesutil set package-1 follow-symbolic-links yes --file ../../tests/test.distribution.imported.pkgproj

 # Package

./packagesutil set follow-symbolic-links yes --file ../../tests/test.raw.package.pkgproj

./packagesutil get follow-symbolic-links --file ../../tests/test.raw.package.pkgproj

./packagesutil set follow-symbolic-links no --file ../../tests/test.raw.package.pkgproj


echo "------ Get HFS+ Compression ------"

 # Distribution Standard

./packagesutil get package-1 use-hfs-compression --file ../../tests/test.distribution.pkgproj

 # Distribution Reference (should fail)

./packagesutil get package-1 use-hfs-compression --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported

./packagesutil get package-1 use-hfs-compression --file ../../tests/test.distribution.imported.pkgproj

 # Package

./packagesutil get use-hfs-compression --file ../../tests/test.raw.package.pkgproj


echo "------ Set HFS+ Compression ------"

 # Distribution Standard

./packagesutil set package-1 use-hfs-compression yes --file ../../tests/test.distribution.pkgproj

./packagesutil get package-1 use-hfs-compression --file ../../tests/test.distribution.pkgproj

./packagesutil set package-1 use-hfs-compression no --file ../../tests/test.distribution.pkgproj

 # Distribution Reference (should fail)

./packagesutil set package-1 use-hfs-compression yes --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported (should fail)

./packagesutil set package-1 use-hfs-compression yes --file ../../tests/test.distribution.imported.pkgproj

 # Package

./packagesutil set use-hfs-compression yes --file ../../tests/test.raw.package.pkgproj

./packagesutil get use-hfs-compression --file ../../tests/test.raw.package.pkgproj

./packagesutil set use-hfs-compression no --file ../../tests/test.raw.package.pkgproj


echo "------ Get Package Location Type ------"

 # Distribution Standard

./packagesutil get package-1 location-type --file ../../tests/test.distribution.pkgproj

 # Distribution Reference

./packagesutil get package-1 location-type --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported

./packagesutil get package-1 location-type --file ../../tests/test.distribution.imported.pkgproj

 # Package (should fail)

./packagesutil get location-type --file ../../tests/test.raw.package.pkgproj


echo "------ Set Package Location Type ------"

 # Distribution Standard

./packagesutil set package-1 location-type custom --file ../../tests/test.distribution.pkgproj

./packagesutil get package-1 location-type --file ../../tests/test.distribution.pkgproj

./packagesutil set package-1 location-type http-url --file ../../tests/test.distribution.pkgproj

./packagesutil get package-1 location-type --file ../../tests/test.distribution.pkgproj

./packagesutil set package-1 location-type removable-media --file ../../tests/test.distribution.pkgproj

./packagesutil get package-1 location-type --file ../../tests/test.distribution.pkgproj

./packagesutil set package-1 location-type embedded --file ../../tests/test.distribution.pkgproj

./packagesutil get package-1 location-type --file ../../tests/test.distribution.pkgproj

# Should fail

./packagesutil set package-1 location-type tutu --file ../../tests/test.distribution.pkgproj

./packagesutil set package-1 location-type --file ../../tests/test.distribution.pkgproj

 # Distribution Reference



./packagesutil set package-1 location-type custom --file ../../tests/test.distribution.reference.pkgproj

./packagesutil get package-1 location-type --file ../../tests/test.distribution.reference.pkgproj

./packagesutil set package-1 location-type http-url --file ../../tests/test.distribution.reference.pkgproj



 # Distribution Imported

./packagesutil set package-1 location-type custom --file ../../tests/test.distribution.imported.pkgproj

./packagesutil get package-1 location-type --file ../../tests/test.distribution.imported.pkgproj

./packagesutil set package-1 location-type embedded --file ../../tests/test.distribution.imported.pkgproj

 # Package (should fail)

./packagesutil set location-type embedded --file ../../tests/test.raw.package.pkgproj


echo "------ Get Package Location Path ------"

 # Distribution Standard

./packagesutil get package-1 location-path --file ../../tests/test.distribution.pkgproj

 # Distribution Reference

./packagesutil get package-1 location-path --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported

./packagesutil get package-1 location-path --file ../../tests/test.distribution.imported.pkgproj

 # Package (should fail)

./packagesutil get location-path --file ../../tests/test.raw.package.pkgproj


echo "------ Set Package Location Path ------"

 # Distribution Standard

./packagesutil set package-1 location-type custom --file ../../tests/test.distribution.pkgproj

./packagesutil set package-1 location-path "/Applications/.." --file ../../tests/test.distribution.pkgproj

./packagesutil get package-1 location-path --file ../../tests/test.distribution.pkgproj

./packagesutil set package-1 location-path "../" --file ../../tests/test.distribution.pkgproj

./packagesutil set package-1 location-type embedded --file ../../tests/test.distribution.pkgproj

 # Distribution Reference

./packagesutil set package-1 location-type custom --file ../../tests/test.distribution.reference.pkgproj

./packagesutil set package-1 location-path "/Applications/.." --file ../../tests/test.distribution.reference.pkgproj

./packagesutil get package-1 location-path --file ../../tests/test.distribution.reference.pkgproj

./packagesutil set package-1 location-path "../" --file ../../tests/test.distribution.reference.pkgproj

./packagesutil set package-1 location-type embedded --file ../../tests/test.distribution.reference.pkgproj

 # Distribution Imported

./packagesutil set package-1 location-type custom --file ../../tests/test.distribution.imported.pkgproj

./packagesutil set package-1 location-path "/Applications/.." --file ../../tests/test.distribution.imported.pkgproj

./packagesutil set package-1 location-path "../" --file ../../tests/test.distribution.imported.pkgproj

./packagesutil get package-1 location-path --file ../../tests/test.distribution.imported.pkgproj

./packagesutil set package-1 location-type embedded --file ../../tests/test.distribution.imported.pkgproj

 # Package (should fail)

./packagesutil set location-path /Applications --file ../../tests/test.raw.package.pkgproj


echo "------ Get Project Certificate Keychain ------"

 # Distribution Standard Bundle (should fail)

./packagesutil get project certificate-keychain --file ../../tests/test.distribution.pkgproj

 # Distribution Standard Flat

./packagesutil get project certificate-keychain --file ../../tests/test.distribution.flat.pkgproj

 # Package

./packagesutil get project certificate-keychain --file ../../tests/test.raw.package.pkgproj


echo "------ Set Project Certificate Keychain ------"

 # Distribution Standard Bundle (should fail)

./packagesutil set project certificate-keychain ˜/Library/Keychain/ --file ../../tests/test.distribution.pkgproj

 # Distribution Standard Flat

./packagesutil set project certificate-keychain ˜/Library/Keychain/ --file ../../tests/test.distribution.flat.pkgproj

./packagesutil get project certificate-keychain --file ../../tests/test.distribution.flat.pkgproj

./packagesutil set project certificate-keychain /Library/Keychain/ --file ../../tests/test.distribution.flat.pkgproj

 # Package

./packagesutil set project certificate-keychain ˜/Library/Keychain/ --file ../../tests/test.raw.package.pkgproj

./packagesutil get project certificate-keychain --file ../../tests/test.raw.package.pkgproj

./packagesutil set project certificate-keychain /Library/Keychain/ --file ../../tests/test.raw.package.pkgproj


echo "------ Get Project Certificate Identity ------"

 # Distribution Standard Bundle (should fail)

./packagesutil get project certificate-identity --file ../../tests/test.distribution.pkgproj

 # Distribution Standard Flat

./packagesutil get project certificate-identity --file ../../tests/test.distribution.flat.pkgproj

 # Package

./packagesutil get project certificate-identity --file ../../tests/test.raw.package.pkgproj


echo "------ Set Project Certificate Identity ------"



echo "------ Help ------"

./packagesutil --help

./packagesutil get --help

./packagesutil set --help

./packagesutil set project --help

./packagesutil get project --help

./packagesutil set package --help

./packagesutil get package --help


echo "------ version ------"

./packagesutil version

exit 0