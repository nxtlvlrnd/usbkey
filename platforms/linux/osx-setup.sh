#! /bin/bash

usbkey_script="osx.sh"
usbkey_setup="setup.sh"
root=`dirname "$0"`

if [[ -f $usbkey_setup ]]; then
  echo "This USBkey hasn't been setup for the target workstation. Please complete the"
  echo "workstation setup first..."
  echo
  echo "Aborting setup!"
  exit 1
fi

cd "$root"
echo "Let's finish setting up your USBkey:"
echo "==="

echo "Creating OSX encrypted disk image. Do not lose your passphrase, it will be"
echo "needed every time that you want to install your identities..."
hdiutil create -stdinpass -attach -encryption AES-256 -type SPARSE -fs HFS+J -volname usbkey -size 100m "osx" 

echo "Transferring identities to new Volume (usbkey)..."
# Move the data to the secure location:
cp *_rsa* /Volumes/usbkey/
# Shred the data:
rm -P *_rsa*

echo "Adjusting permissions..."
chmod 600 /Volumes/usbkey/*_rsa
chmod 644 /Volumes/usbkey/*_rsa.pub

echo "Ejecting new Volume..."
hdiutil eject /Volumes/usbkey

echo "Creating script for identity management..."
cat > $usbkey_script << EOF
#! /bin/bash
root=\`dirname "\$0"\`
cd "\$root"
echo "Mounting image..."
hdiutil attach osx.sparseimage
echo "Adding identities..."
for ident in \`ls /Volumes/usbkey/*_rsa\`; do 
  ssh-add -t 7200 \$ident
done
echo "All identities active for the next 2 hours!"
hdiutil eject /Volumes/usbkey
EOF
chmod 500 $usbkey_script

echo "All done! This script will self-implode on exit -- but will be replaced with"
echo "one that mounts the image, adds your identities, and unmounts the USBkey."
echo
echo "Just run the '$usbkey_script' script to use your identities."

# Self deleting script:
#--#rm -- "$0"
