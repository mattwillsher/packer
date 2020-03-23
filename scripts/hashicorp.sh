#!/bin/bash

set -euox pipefail

tool="$TOOL"
version="$VERSION"

arch="$(arch)"
os=$(uname -s|tr '[:upper:]' '[:lower:]')

toolversion="${tool}_${version}"

url="https://releases.hashicorp.com/${tool}/${version}"
archive="${toolversion}_${os}_${arch}.zip"
shasums="${toolversion}_SHA256SUMS"
shasums_sig="${toolversion}_SHA256SUMS.sig"

# Download the loot
for file in "$archive" "$shasums" "$shasums_sig"; do
	test -f "$file" || wget -nv "$url/$file"
done

# Check SHASUM file signature against the one above
gpg --verify "$shasums_sig"

# Find the downloaded file in the SHASUM file and check against the
# downloaded tool
grep "$archive" "$shasums" | shasum -c -

# Extract, prep and copy the tool binary into place
unzip "$archive"
sudo chown root:root "$tool"
sudo chmod +x "$tool"
mkdir -p /opt/bin
sudo mv "$tool" "/opt/bin/$tool"

rm "$archive" "$shasums" "$shasums_sig"

exit
