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

USB_PRESENT=$(lsblk -o PATH,SERIAL | grep 4C530001081102122170 | cut -f1 -d" ")
sudo dd if="${file%.zip}" of="$USB_PRESENT" bs=4M status=progress
