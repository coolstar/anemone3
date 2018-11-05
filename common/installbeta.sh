#!/bin/bash

echo "Anemone beta installation script."
echo "Copyright (C) 2016, CoolStar. All Rights Reserved."

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ ! -f Anemone.dylib ]; then
    echo "Please cd to the directory containing the Anemone beta build." 1>&2
    exit 2
fi

if [ ! -f /Library/MobileSubstrate/DynamicLibraries/Anemone.dylib ]; then
	echo "Error: You must have either Anemone stable or a previous Anemone beta to update to the new one." 1>&2
	exit 3
fi

echo " "
echo "Warning: Each build is unique per person. Do not distribute."
echo " "
echo "Unloading Optitheme..."

launchctl unload /Library/LaunchDaemons/com.anemonetheming.optitheme.plist

echo "Uninstalling old Anemone build..."

rm /Library/MobileSubstrate/DynamicLibraries/Anemone.dylib
rm /Library/MobileSubstrate/DynamicLibraries/Anemone*.dylib
rm /Library/MobileSubstrate/DynamicLibraries/z_AnemoneIconEffects.dylib
rm /usr/bin/recache
rm /usr/bin/AnemoneOptimizer
rm /usr/bin/cardump

rm -rf /Applications/Anemone.app

echo "Copying new Anemone build..."

cp *.dylib /Library/MobileSubstrate/DynamicLibraries

cp cardump /usr/bin/cardump
cp AnemoneOptimizer /usr/bin/AnemoneOptimizer
cp recache /usr/bin/recache

cp -Rp Anemone.app /Applications/Anemone.app

chmod -R 0644 /Applications/Anemone.app
chmod 0755 /Applications/Anemone.app/Anemone
chmod 0755 /Applications/Anemone.app
chmod 0755 /usr/bin/cardump
chmod 0755 /usr/bin/AnemoneOptimizer
chmod 0755 /usr/bin/recache

echo "Loading Optitheme..."

launchctl load /Library/LaunchDaemons/com.anemonetheming.optitheme.plist

echo "Clearing Caches..."
recache --no-respring

echo "Done. Please Respring to Use the new Anemone build!"