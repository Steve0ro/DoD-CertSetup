#!/usr/bin/env bash

# Original author: https://github.com/jdjaxon/linux_cac/
# Modified by: Steve0ro
# Description: Setup Common Access Card use with DoD certificates installed for Google Chrome.

main () {
    EXIT_SUCCESS=0                      # Success exit code
    E_NOTROOT=86                        # Non-root exit error
    E_BROWSER=87                        # Compatible browser not found
    DWNLD_DIR="/tmp"                    # Location to place artifacts
    CERT_EXTENSION="cer"
    CERT_FILENAME="AllCerts"
    BUNDLE_FILENAME="AllCerts.zip"
    CERT_URL="http://militarycac.com/maccerts/$BUNDLE_FILENAME"

    chrome_exists=false

    ORIG_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"

    root_check
    browser_check
    print_info "Installing middleware and essential utilities..."
    apt update
    DEBIAN_FRONTEND=noninteractive apt install -y libpcsclite1 pcscd libccid libpcsc-perl pcsc-tools libnss3-tools unzip wget opensc
    print_info "Done"
    print_info "Downloading DoD certificates..."
    wget -qP "$DWNLD_DIR" "$CERT_URL"
    print_info "Done."

    if [ -e "$DWNLD_DIR/$BUNDLE_FILENAME" ]; then
        mkdir -p "$DWNLD_DIR/$CERT_FILENAME"
        unzip "$DWNLD_DIR/$BUNDLE_FILENAME" -d "$DWNLD_DIR/$CERT_FILENAME"
    fi

    databases=($(find "$ORIG_HOME" -name "cert9.db" 2>/dev/null | grep "pki"))
    if [ "${#databases[@]}" -eq 0 ]; then
        print_err "No valid Chrome NSS databases located. Try running Chrome once and then re-run this script."
        exit $E_BROWSER
    fi

    for db in "${databases[@]}"; do
        if [ -n "$db" ]; then
            import_certs "$db"
        fi
    done

    print_info "Registering CAC module with PKCS11..."
    pkcs11-register
    print_info "Done"

    print_info "Enabling pcscd service to start on boot..."
    systemctl enable pcscd.socket
    print_info "Done"

    print_info "Removing artifacts..."
    rm -rf "${DWNLD_DIR:?}"/{"$BUNDLE_FILENAME","$CERT_FILENAME"} 2>/dev/null
    if [ "$?" -ne "$EXIT_SUCCESS" ]; then
        print_err "Failed to remove artifacts. Artifacts were stored in ${DWNLD_DIR}."
    else
        print_info "Done. A reboot may be required."
    fi

    exit "$EXIT_SUCCESS"
}


print_err () {
    ERR_COLOR='\033[0;31m'
    NO_COLOR='\033[0m'
    echo -e "${ERR_COLOR}[ERROR]${NO_COLOR} $1"
}


print_info () {
    INFO_COLOR='\033[0;33m'
    NO_COLOR='\033[0m'
    echo -e "${INFO_COLOR}[INFO]${NO_COLOR} $1"
}


root_check () {
    local ROOT_UID=0
    if [ "${EUID:-$(id -u)}" -ne "$ROOT_UID" ]; then
        print_err "Please run this script as root."
        exit "$E_NOTROOT"
    fi
}

browser_check () {
    print_info "Checking for Google Chrome..."
    if command -v google-chrome >/dev/null; then
        chrome_exists=true
        print_info "Found Google Chrome."
    else
        print_err "Google Chrome not found. Please install Google Chrome and re-run this script."
        exit $E_BROWSER
    fi
}


import_certs () {
    db=$1
    db_root="$(dirname "$db")"

    if [ -n "$db_root" ]; then
        print_info "Importing certificates for Chrome into $db_root..."

        for cert in "$DWNLD_DIR/$CERT_FILENAME/"*."$CERT_EXTENSION"; do
            echo "Importing $cert"
            certutil -d sql:"$db_root" -A -t TC -n "$cert" -i "$cert"
        done
        print_info "Certificates successfully imported into $db_root."
    fi
}

main

