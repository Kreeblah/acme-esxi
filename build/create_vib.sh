#!/bin/bash
#
# Original script Copyright (c) Johannes Feichtner <johannes@web-wack.at>]
# Modified slightly for acme-esxi
#
# Script to build acme-esxi VIB using VIB Author

LOCALDIR=$(dirname "$(readlink -f "$0")")
TEMP_DIR=/tmp/acme-esxi-$$

# Ensure prerequisites are installed
git version > /dev/null 2>&1
if [ $? -eq 1 ]; then
  echo "git not installed, exiting..."
  exit 1
fi

vibauthor --version > /dev/null 2>&1
if [ $? -eq 1 ]; then
  echo "vibauthor not installed, exiting .."
  exit 1
fi

VIB_NAME=acme-esxi.vib
OFFLINE_BUNDLE_NAME=acme-esxi-offline-bundle.zip


# Define VIB metadata
cd "${LOCALDIR}" || exit

VIB_DATE=$(date --date="$(git log -n1 --format="%cd" --date="iso")" '+%Y-%m-%dT%H:%I:%S')
VIB_TAG=$(git describe --tags --abbrev=0 --match '[0-9]*.[0-9]*.[0-9]*' 2> /dev/null || echo 0.0.1)

# Setting up VIB spec confs
VIB_DESC_FILE=${TEMP_DIR}/descriptor.xml
VIB_PAYLOAD_DIR=${TEMP_DIR}/payloads/payload1

# Create acme-esxi temp dir
mkdir -p ${TEMP_DIR}
# Create VIB spec payload directory
mkdir -p ${VIB_PAYLOAD_DIR}

# Create target directory
BIN_DIR=${VIB_PAYLOAD_DIR}/opt/acme-esxi
INIT_DIR=${VIB_PAYLOAD_DIR}/etc/init.d
mkdir -p ${BIN_DIR} ${INIT_DIR}

# Copy files to the corresponding locations
cp ../* ${BIN_DIR} 2>/dev/null
cp ../acme-esxi ${INIT_DIR}

# Ensure that shell scripts are executable
chmod +x ${INIT_DIR}/acme-esxi ${BIN_DIR}/renew.sh

# Create tgz with payload
tar czf ${TEMP_DIR}/payload1 -C ${VIB_PAYLOAD_DIR} opt etc

# Calculate payload size/hash
PAYLOAD_FILES=$(tar tf ${TEMP_DIR}/payload1 | grep -v -E '/$' | sed -e 's/^/    <file>/' -e 's/$/<\/file>/')
PAYLOAD_SIZE=$(stat -c %s ${TEMP_DIR}/payload1)
PAYLOAD_SHA256=$(sha256sum ${TEMP_DIR}/payload1 | awk '{print $1}')
PAYLOAD_SHA256_ZCAT=$(zcat ${TEMP_DIR}/payload1 | sha256sum | awk '{print $1}')
PAYLOAD_SHA1_ZCAT=$(zcat ${TEMP_DIR}/payload1 | sha1sum | awk '{print $1}')

# Create acme-esxi VIB descriptor.xml
cat > ${VIB_DESC_FILE} << __W2C__
<vib version="5.0">
  <type>bootbank</type>
  <name>acme-esxi</name>
  <version>${VIB_TAG}-0.0.0</version>
  <vendor>natethesage</vendor>
  <summary>ACME and Let's Encrypt for ESXi</summary>
  <description>ACME and Let's Encrypt for ESXi</description>
  <release-date>${VIB_DATE}</release-date>
  <urls>
    <url key="acme-esxi">https://github.com/NateTheSage/acme-esxi</url>
  </urls>
  <relationships>
    <depends/>
    <conflicts/>
    <replaces/>
    <provides/>
    <compatibleWith/>
  </relationships>
  <software-tags/>
  <system-requires>
    <maintenance-mode>false</maintenance-mode>
  </system-requires>
  <file-list>
  </file-list>
  <acceptance-level>community</acceptance-level>
  <live-install-allowed>true</live-install-allowed>
  <live-remove-allowed>true</live-remove-allowed>
  <cimom-restart>false</cimom-restart>
  <stateless-ready>true</stateless-ready>
  <overlay>false</overlay>
  <payloads>
    <payload name="payload1" type="tgz" size="${PAYLOAD_SIZE}">
        <checksum checksum-type="sha-256">${PAYLOAD_SHA256}</checksum>
        <checksum checksum-type="sha-256" verify-process="gunzip">${PAYLOAD_SHA256_ZCAT}</checksum>
        <checksum checksum-type="sha-1" verify-process="gunzip">${PAYLOAD_SHA1_ZCAT}</checksum>
    </payload>
  </payloads>
</vib>
__W2C__

# Create VIB using ar
touch ${TEMP_DIR}/sig.pkcs7
ar r ${VIB_NAME} ${TEMP_DIR}/descriptor.xml ${TEMP_DIR}/sig.pkcs7 ${TEMP_DIR}/payload1

# Create offline bundle
PYTHONPATH=/opt/vmware/vibtools-6.0.0-847598/bin python -c "import vibauthorImpl; vibauthorImpl.CreateOfflineBundle(\"${VIB_NAME}\", \"${OFFLINE_BUNDLE_NAME}\", True)"

# Show some details about what we have just created
vibauthor -i -v acme-esxi.vib

# Remove acme-esxi temp dir
rm -rf ${TEMP_DIR}
