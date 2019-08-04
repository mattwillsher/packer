#!/bin/bash

# A simple script to install Hashicorp tools with GPG key verification

set -euo pipefail

# Set DEST_PATH if not already set
HASHI_DEST_PATH="${HASHI_DEST_PATH:-/usr/local/bin}"
# Clean up downloaded files
HASHI_CLEAN="${HASHI_CLEAN:-true}"

# Install the Hashicorp Security GPG key.
# Verify key data at https://www.hashicorp.com/security.html
function hashiseckey {
	gpg -kv 91A6E7F85D05C65630BEF18951852D87348FFC4C && return
	cat <<EOF | gpg --import
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1

mQENBFMORM0BCADBRyKO1MhCirazOSVwcfTr1xUxjPvfxD3hjUwHtjsOy/bT6p9f
W2mRPfwnq2JB5As+paL3UGDsSRDnK9KAxQb0NNF4+eVhr/EJ18s3wwXXDMjpIifq
fIm2WyH3G+aRLTLPIpscUNKDyxFOUbsmgXAmJ46Re1fn8uKxKRHbfa39aeuEYWFA
3drdL1WoUngvED7f+RnKBK2G6ZEpO+LDovQk19xGjiMTtPJrjMjZJ3QXqPvx5wca
KSZLr4lMTuoTI/ZXyZy5bD4tShiZz6KcyX27cD70q2iRcEZ0poLKHyEIDAi3TM5k
SwbbWBFd5RNPOR0qzrb/0p9ksKK48IIfH2FvABEBAAG0K0hhc2hpQ29ycCBTZWN1
cml0eSA8c2VjdXJpdHlAaGFzaGljb3JwLmNvbT6JATgEEwECACIFAlMORM0CGwMG
CwkIBwMCBhUIAgkKCwQWAgMBAh4BAheAAAoJEFGFLYc0j/xMyWIIAIPhcVqiQ59n
Jc07gjUX0SWBJAxEG1lKxfzS4Xp+57h2xxTpdotGQ1fZwsihaIqow337YHQI3q0i
SqV534Ms+j/tU7X8sq11xFJIeEVG8PASRCwmryUwghFKPlHETQ8jJ+Y8+1asRydi
psP3B/5Mjhqv/uOK+Vy3zAyIpyDOMtIpOVfjSpCplVRdtSTFWBu9Em7j5I2HMn1w
sJZnJgXKpybpibGiiTtmnFLOwibmprSu04rsnP4ncdC2XRD4wIjoyA+4PKgX3sCO
klEzKryWYBmLkJOMDdo52LttP3279s7XrkLEE7ia0fXa2c12EQ0f0DQ1tGUvyVEW
WmJVccm5bq25AQ0EUw5EzQEIANaPUY04/g7AmYkOMjaCZ6iTp9hB5Rsj/4ee/ln9
wArzRO9+3eejLWh53FoN1rO+su7tiXJA5YAzVy6tuolrqjM8DBztPxdLBbEi4V+j
2tK0dATdBQBHEh3OJApO2UBtcjaZBT31zrG9K55D+CrcgIVEHAKY8Cb4kLBkb5wM
skn+DrASKU0BNIV1qRsxfiUdQHZfSqtp004nrql1lbFMLFEuiY8FZrkkQ9qduixo
mTT6f34/oiY+Jam3zCK7RDN/OjuWheIPGj/Qbx9JuNiwgX6yRj7OE1tjUx6d8g9y
0H1fmLJbb3WZZbuuGFnK6qrE3bGeY8+AWaJAZ37wpWh1p0cAEQEAAYkBHwQYAQIA
CQUCUw5EzQIbDAAKCRBRhS2HNI/8TJntCAClU7TOO/X053eKF1jqNW4A1qpxctVc
z8eTcY8Om5O4f6a/rfxfNFKn9Qyja/OG1xWNobETy7MiMXYjaa8uUx5iFy6kMVaP
0BXJ59NLZjMARGw6lVTYDTIvzqqqwLxgliSDfSnqUhubGwvykANPO+93BBx89MRG
unNoYGXtPlhNFrAsB1VR8+EyKLv2HQtGCPSFBhrjuzH3gxGibNDDdFQLxxuJWepJ
EK1UbTS4ms0NgZ2Uknqn1WRU1Ki7rE4sTy68iZtWpKQXZEJa0IGnuI2sSINGcXCJ
oEIgXTMyCILo34Fa/C6VCm2WBgz9zZO8/rHIiQm1J5zqz0DrDwKBUM9C
=LYpS
-----END PGP PUBLIC KEY BLOCK-----
EOF

}

function nomadsystemd {
	cat <<EOF | sudo tee /etc/systemd/system/nomad.service
[Unit]
Description=Nomad
Documentation=https://nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

# When using Nomad with Consul it is not necessary to start Consul first. These
# lines start Consul before Nomad as an optimization to avoid Nomad logging
# that Consul is unavailable at startup.
#Wants=consul.service
#After=consul.service

[Service]
ExecReload=/bin/kill -HUP \$MAINPID
ExecStart=$HASHI_DEST_PATH/nomad agent -config /etc/nomad.d
KillMode=process
KillSignal=SIGINT
LimitNOFILE=65536
LimitNPROC=infinity
Restart=on-failure
RestartSec=2
StartLimitBurst=3
StartLimitIntervalSec=10
TasksMax=infinity

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable consul
}

function consulsystemd {
	cat <<EOF | sudo tee /etc/systemd/system/consul.service
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
User=consul
Group=consul
ExecStart=$HASHI_DEST_PATH/consul agent -config-dir=/etc/consul.d/
ExecReload=$HASHI_DEST_PATH/consul reload
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable consul
}

function vaultsystemd {
	cat <<EOF | sudo tee /etc/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=$HASHI_DEST_PATH/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitIntervalSec=60
StartLimitBurst=3
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable consul
}

# Install the given hashitool. Takes tool name, version and option architecture
function hashiinstall {
	local tool="$1"
	local version="$2"
	local arch="${3:-amd64}"

	local archive="${tool}_${version}_linux_${arch}.zip"
	local shasums="${tool}_${version}_SHA256SUMS"
	local shasig="${tool}_${version}_SHA256SUMS.sig"
	local url="https://releases.hashicorp.com/${tool}/${version}"
	local toolpath="$HASHI_DEST_PATH/$tool"

	# If $tool is already in $HASHI_DEST_PATH, check if its version matches
	# $version
	if [ -x "$toolpath" ]; then
		cversion=$( "$toolpath" --version | grep -E '[0-9]+\.[0-9]+\.[0-9]+' )
		if [ "$version" == "$cversion" ]; then
			echo "$tool $version already installed"
			return
		fi
	fi

	# Download the loot
	for file in "$archive" "$shasums" "$shasig"; do
		test -f "$file" || wget -nv "$url/$file"
	done

	# Check SHASUM file signature against the one above
	gpg --verify "$shasig"

	# Find the downloaded file in the SHASUM file and check against the
	# downloaded tool
	grep "$archive" "$shasums" | shasum -c -

    # Extract, prep and copy the tool binary into place
	test -f "$tool" || unzip "$archive"
	sudo chown root:root "$tool"
	test -d "$HASHI_DEST_PATH" || mkdir -p "$HASHI_DEST_PATH"
	sudo mv "$tool" "$toolpath"

	# Clean up
	if [ "$HASHI_CLEAN" = true ]; then
		rm "$archive" "$shasums" "$shasig"
	fi
}

hashiseckey
hashiinstall consul 1.5.3
hashiinstall nomad 0.9.4
hashiinstall vault 1.2.0
consulsystemd
nomadsystemd
vaultsystemd
exit
