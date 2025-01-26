# Termux - Ubuntu

A script to install Ubuntu in Termux, making it easy to run a full Ubuntu environment on your Android device. The installation is fully automated and with just a single command, you can get Ubuntu running in Termux.

## Features

- **One-command Installation**: Easily install Ubuntu with a single `curl` command.
- **Customizable Installation**: Choose where you want to install Ubuntu and the Ubuntu version.
- **Networking Setup**: Automatically configures `resolv.conf` for internet access.
- **Automatic Setup**: Downloads the Ubuntu root filesystem, decompresses it, and sets up everything required to run Ubuntu in Termux.

## Requirements

- **Termux**: Ensure you have Termux installed on your Android device. You can download it from [Google Play](https://play.google.com/store/apps/details?id=com.termux) or [F-Droid](https://f-droid.org/packages/com.termux/).
- **Sufficient Storage**: Make sure your device has enough storage space for the Ubuntu root filesystem.
- **Internet Access**: The script downloads the necessary files from the internet, so a stable connection is required.
- **Curl Installed**: You need *curl* installed in termux to use the script.
   
## Installation

### Run the Installation Command

To install Ubuntu in Termux, run the following command in Termux:

```bash
curl -fsSL https://raw.githubusercontent.com/TIS199/termux-ubuntu/main/ubuntu.sh | bash
```
If you don't have curl installed then run this command first:
```bash
apt update && apt install curl -y
