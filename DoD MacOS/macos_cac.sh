#!/bin/bash

main () {
    EXIT_SUCCESS=0                      # Success exit code
    E_NOTROOT=86                        # Non-root exit error
    E_BROWSER=87                        # Compatible browser not found
    E_DATABASE=88                       # No database located
    DWNLD_DIR="/tmp"                    # Location to place artifacts
    CERT_EXTENSION="cer"
    CERT_FILENAME="AllCerts"
    BUNDLE_FILENAME="AllCerts.zip"
    CERT_URL="http://militarycac.com/maccerts/$BUNDLE_FILENAME"
    CAC_MODULE_PATH="/usr/local/lib/pkcs11/opensc-pkcs11.so" # Default path for OpenSC

    root_check
    browser_check
    install_utilities
    download_certs
    import_certs_to_system_store
    configure_firefox
    enable_pcscd
    cleanup

    echo "CAC setup complete. A system reboot may be required."
    exit "$EXIT_SUCCESS"
}

root_check () {
    if [[ $EUID -ne 0 ]]; then
        echo "[ERROR] Please run this script as root." >&2
        exit "$E_NOTROOT"
    fi
}

browser_check () {
    echo "[INFO] Checking for installed browsers..."
    chrome_installed=false
    firefox_installed=false

    if command -v google-chrome > /dev/null; then
        echo "[INFO] Google Chrome is installed."
        chrome_installed=true
    fi

    if command -v firefox > /dev/null; then
        echo "[INFO] Mozilla Firefox is installed."
        firefox_installed=true
    fi

    if ! $chrome_installed && ! $firefox_installed; then
        echo "[ERROR] No compatible browser found. Please install Google Chrome or Mozilla Firefox." >&2
        exit "$E_BROWSER"
    fi
}

install_utilities () {
    echo "[INFO] Installing required utilities..."
    if ! command -v brew > /dev/null; then
        echo "[INFO] Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    brew update
    brew install opensc openssl wget unzip libpcsclite pcsc-tools
    echo "[INFO] Required utilities installed."
}

download_certs () {
    echo "[INFO] Downloading DoD certificates..."
    mkdir -p "$DWNLD_DIR/$CERT_FILENAME"
    wget -qO "$DWNLD_DIR/$BUNDLE_FILENAME" "$CERT_URL"
    unzip -oq "$DWNLD_DIR/$BUNDLE_FILENAME" -d "$DWNLD_DIR/$CERT_FILENAME"
    echo "[INFO] Certificates downloaded and extracted."
}

import_certs_to_system_store () {
    echo "[INFO] Importing DoD certificates into macOS system keychain..."
    for cert in "$DWNLD_DIR/$CERT_FILENAME"/*."$CERT_EXTENSION"; do
        echo "[INFO] Importing $cert..."
        security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$cert"
    done
    echo "[INFO] Certificates imported into system keychain."
}

configure_firefox () {
    echo "[INFO] Configuring Firefox for CAC use..."
    firefox_profiles_dir="$HOME/Library/Application Support/Firefox/Profiles"
    if [[ -d "$firefox_profiles_dir" ]]; then
        for profile_dir in "$firefox_profiles_dir"/*; do
            if [[ -d "$profile_dir" ]]; then
                echo "[INFO] Configuring profile: $profile_dir"
                mkdir -p "$profile_dir" && echo "library=$CAC_MODULE_PATH" > "$profile_dir/pkcs11.txt"
                certutil -d sql:"$profile_dir" -N --empty-password
                for cert in "$DWNLD_DIR/$CERT_FILENAME"/*."$CERT_EXTENSION"; do
                    certutil -d sql:"$profile_dir" -A -t "CT,C,C" -n "$(basename "$cert")" -i "$cert"
                done
            fi
        done
    else
        echo "[ERROR] Firefox profile directory not found. Please run Firefox at least once before running this script." >&2
    fi
}

enable_pcscd () {
    echo "[INFO] Enabling PC/SC service for CAC reader support..."
    brew services start pcscd
    echo "[INFO] PC/SC service enabled."
}

cleanup () {
    echo "[INFO] Cleaning up temporary files..."
    rm -rf "$DWNLD_DIR/$BUNDLE_FILENAME" "$DWNLD_DIR/$CERT_FILENAME"
    echo "[INFO] Temporary files cleaned up."
}

main
