#!/data/data/com.termux/files/usr/bin/bash

function blue_print() {
    echo -e "\x1b[38;5;83m[Downloader]:\e[0m \x1b[38;5;87m $1"
}

# Check for necessary packages and install if missing
blue_print "Checking and installing necessary packages..."
pkg update -y && pkg install -y proot proot-distro wget curl tar


# Map architecture
ARCH=$(uname -m)
case "$ARCH" in
    aarch64) ARCH="arm64" ;;
    armv7l) ARCH="armhf" ;;
    arm) ARCH="armhf" ;;
    x86_64) ARCH="amd64" ;;
    i386|i686) ARCH="i386" ;;
    arm64|armhf|amd64|ppc64el|s390x) ;; # Valid architectures
    *)
        blue_print "Architecture '$ARCH' is unsupported. Please choose one:"
        echo "Options: amd64, arm64, armhf, i386, ppc64el, s390x, or use a custom file."
        read -p "Enter architecture (or 'custom'): " ARCH
        if [[ "$ARCH" == "custom" ]]; then
            read -p "Enter the path to the custom Ubuntu base file: " CUSTOM_FILE
            if [[ ! -f "$CUSTOM_FILE" ]]; then
                blue_print "Custom file not found. Exiting."
                exit 1
            fi
        fi
        ;;
esac
blue_print "Detected/Selected architecture: $ARCH"

# Display Ubuntu versions
blue_print "Supported Ubuntu versions:"
echo "1) bionic (18.04)"
echo "2) focal (20.04)"
echo "3) jammy (22.04)"
echo "4) noble (24.04)"
echo "5) Enter custom URL"
echo "6) Use a custom file"

# Get version choice
read -p "Choose an option (1-6): " CHOICE
case "$CHOICE" in
    1) UBUNTU_VERSION="bionic" ;;
    2) UBUNTU_VERSION="focal" ;;
    3) UBUNTU_VERSION="jammy" ;;
    4) UBUNTU_VERSION="noble" ;;
    5) 
        read -p "Enter custom URL: " CUSTOM_URL
        ;;
    6)
        read -p "Enter the path to the custom Ubuntu base file: " CUSTOM_FILE
        if [[ ! -f "$CUSTOM_FILE" ]]; then
            blue_print "Custom file not found. Exiting."
            exit 1
        fi
        ;;
    *)
        blue_print "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Download Ubuntu base
if [[ -z "$CUSTOM_FILE" ]]; then
    if [[ -z "$CUSTOM_URL" ]]; then
        UBUNTU_URL="https://cdimage.ubuntu.com/ubuntu-base/${UBUNTU_VERSION}/daily/current/${UBUNTU_VERSION}-base-${ARCH}.tar.gz"
    else
        UBUNTU_URL="$CUSTOM_URL"
    fi

    blue_print "Downloading Ubuntu base from $UBUNTU_URL..."
    wget -q --show-progress "$UBUNTU_URL" -O ubuntu.tar.gz
    if [[ $? -ne 0 ]]; then
        blue_print "Failed to download Ubuntu base. Exiting."
        exit 1
    fi
else
    blue_print "Using custom file: $CUSTOM_FILE"
    cp "$CUSTOM_FILE" ubuntu.tar.gz
fi

# Define variables
cur=$(pwd)
directory="ubuntu-fs"
bin="startubuntu.sh"

# Function to print colored messages
function log_info() {
    echo -e "\x1b[38;5;83m[Installer]:\e[0m \x1b[38;5;87m $1"
}

# Installation Function
function install_ubuntu() {
    printf "\x1b[38;5;214m\e[0m\x1b[38;5;127m[INFO]:\e[0m \x1b[38;5;87m Downloaded Ubuntu-base.\n"
    mkdir -p "$directory"
    cd "$directory" || exit

    # Decompress Ubuntu Rootfs
    log_info "Decompressing the Ubuntu rootfs, please wait..."
    proot --link2symlink tar -zxf "$cur/ubuntu.tar.gz" --exclude='dev' || :
    log_info "The Ubuntu rootfs has been successfully decompressed!"

    # Fix Internet Access (resolv.conf)
    log_info "Fixing the resolv.conf to enable internet access..."
    printf "nameserver 8.8.8.8\nnameserver 8.8.4.4\n" > etc/resolv.conf
    log_info "Internet access configuration completed."

    # Write Stub Files
    stubs=("usr/bin/groups")
    for stub in "${stubs[@]}"; do
        log_info "Writing stubs for compatibility..."
        echo -e "#!/bin/sh\nexit" > "$stub"
    done
    log_info "Stub files have been successfully written!"

    cd "$cur" || exit

    # Create Start Script
    mkdir -p ubuntu-binds
    log_info "Creating the start script, please wait..."
    cat > "$bin" <<- EOM
#!/bin/bash
cd \$(dirname \$0)
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $directory"
if [ -n "\$(ls -A ubuntu-binds)" ]; then
    for f in ubuntu-binds/* ; do
        . \$f
    done
fi
command+=" -b /dev"
command+=" -b /proc"
command+=" -b /sys"
command+=" -b ubuntu-fs/tmp:/dev/shm"
command+=" -b /data/data/com.termux"
command+=" -b /:/host-rootfs"
command+=" -b /sdcard"
command+=" -b /storage"
command+=" -b /mnt"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="\$@"
if [ -z "\$1" ]; then
    exec \$command
else
    \$command -c "\$com"
fi
EOM
    log_info "The start script has been successfully created!"

    # Fix Shebang and Make Executable
    log_info "Fixing the shebang of $bin..."
    termux-fix-shebang "$bin"
    log_info "Successfully fixed the shebang!"

    log_info "Making $bin executable, please wait..."
    chmod +x "$bin"
    log_info "Successfully made $bin executable."

    # Cleanup
    log_info "Cleaning up installation files, please wait..."
    rm -rf "$cur/ubuntu.tar.gz"
    log_info "Successfully cleaned up temporary files!"

    log_info "Installation complete! You can now launch Ubuntu with ./$bin"
}

install_ubuntu
