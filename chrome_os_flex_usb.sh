#!/bin/bash
echo "Flashing the latest Chrome OS flex"
set -eu

json="https://dl.google.com/dl/edgedl/chromeos/recovery/cloudready_recovery.json"
echo "Downloading json file"
wget "$json"
url=$(cat cloudready_recovery.json | jq -r ".[].url" )
file=$(basename "$url")
wget "$url"


if [ "$(md5sum "$file" | awk '{print $1}')" != "$(cat cloudready_recovery.json | jq -r '.[].md5')" ]; then
    echo "MD5 Checksum DOES NOT match for $file. WARNING: File may be corrupted or tampered with!"
    exit
fi
echo "MD5 Checksum matches for $file. Integrity OK."

EXPECTED_SHA1=$(cat cloudready_recovery.json | jq -r ".[].sha1")
echo "Expected SHA-1: $EXPECTED_SHA1"

if [ "$(sha1sum "$file" | awk '{print $1}')" != "$(cat cloudready_recovery.json | jq -r '.[].sha1')" ]; then
    echo "SHA-1 Checksum DOES NOT match for $file. WARNING: File may be corrupted or tampered with!"
    exit
fi
echo "SHA-1 Checksum matches for $file. Integrity OK."

unzip "$file"
rm "$file"

if [ "$(md5sum "$file" | awk '{print $1}')" != "$(cat cloudready_recovery.json | jq -r '.[].md5')" ]; then
    echo "MD5 Checksum DOES NOT match for $file. WARNING: File may be corrupted or tampered with!"
    exit
fi

usb_serial="$(udevadm info --query=all --name=/dev/sdb | grep "ID_SERIAL_SHORT=" | awk -F'=' '{print $2}')"

if [ "$usb_serial" == "4C530001081102122170" ]; then
  sudo dd if="${file%.zip}" of=/dev/sdb bs=4M status=progress
else
  echo "Wrong USB stick"
fi
echo "Flashing the latest Chrome OS flex"
