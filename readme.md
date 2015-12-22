Overview
===================================================

bluetooth_6lowpand is the commissioning daemon running on Linux that helps
to establish 6LoWPAN connection with IPSP supported BLE devices. It is based
on the Linux BlueZ HCI and management interface and provides different options
for commissioning.

Currently it supports 2 different approaches:

 1. Authentication with WiFi keys: By starting the daemon with "-a" option, the
    daemon will reuse the WiFi authentication keys and establish an encrypted 
    connection with IPSP devices using Passkey. Thus password has to have
    6-ascii digits syntax.

 2. Whitelisting: By adding IPSP devices into the whitelist by using the "addwl" command,
    the daemon will automatically establish connection with the IPSP device.

Changes Note
===================================================
### 1.0.0
 - 1st release with following feature.
 - command "addwl" to add IPSP device into whitelist.
 - command "rmwl" to remove IPSP device from whitelist.
 - command "lswl" to show current IPSP devices present in the whitelist.
 - command "lscon" to show current bluetooth 6lowpan connections.
 - option "-w" to set the time of each device scanning.
 - option "-d" to daemonize the program.
 - option "-a" to authenticate with WiFi keys.

Known Issues
===================================================

 - bluetoothd daemon has to be killed to allow passkey/oob pairing. 
   The command below should be executed before running the bluetooth_6lowpand daemon
   with the -a option if the bluetoothd daemon is running.

        $ killall bluetoothd


 - If all the devices are disconnected, the 6lowpan network interface on OpenWRT 
   will be brought down. Once a BLE connection is recovered, you will have to go to the 
   web UI (LuCi) and connect the 6lowpan network interface manually.

 - For Linux kernel versions greater than 4.1.6 pairing using passkey does not work
   because of "SMP security requested but not available" error.

Package Contents
===================================================

    | Path            | Description                                             |
    |-----------------|---------------------------------------------------------|
    | Readme.md       | Documentation.                                          |
    | src/            | Source files of the daemon and init.d script.           |
    | src/bluez       | Link to bluez Git repository.                           |
    | patches/openwrt | Patch to apply bluetooth_6lowpand in bluez for OpenWrt. |
    | patches/ubuntu  | Patch to build bluetooth_6lowpand in bluez for Ubuntu.  |

How to Build
===================================================

### How to build for Ubuntu:

 -  On Ubuntu 15.10 LTS, install the following necessary packages:

        $ sudo apt-get install git-core build-essential libssl-dev libncurses5-dev unzip gawk subversion mercurial automake libtool libglib2.0-dev libdbus-1-dev libudev-dev libical-dev libreadline6-dev libbluetooth-dev 


 -  Download bluez 5.30 sources from the linked repository
    
        $ git submodule update --init

        # The operation above might be done manually:
        # $ cd src
        # $ git clone https://kernel.googlesource.com/pub/scm/bluetooth/bluez.git -b 5.30


 -  Apply the patch

        $ cd src/bluez
        $ cp ../../patches/ubuntu/bluetooth_6lowpand_5.30-1.patch .
        $ git apply bluetooth_6lowpand_5.30-1.patch


 -  Build Bluez with the daemon

        $ ./bootstrap-configure --disable-android --disable-systemd 
        $ make tools/bluetooth_6lowpand

        # Note that you may also build and install complete Bluez 5.30 version by using
        # 'make all' and 'make install' commands.
        # Alternatively copy the daemon to the user space
        $ cp tools/bluetooth_6lowpand /usr/sbin/


 -  The last step is to copy the init.d script and create a file for the whitelist (if needed).

        $ cp ../bluetooth_6lowpand.init /etc/init.d/bluetooth_6lowpand
        $ chmod 755 /etc/init.d/bluetooth_6lowpand
        $ mkdir /etc/config
        $ touch /etc/config/bluetooth_6lowpand.conf

### How to build for OpenWrt:

##### Cross-compilation section:

 -  On Ubuntu 14.04 LTS / 15.10, install the following necessary packages:

        $ sudo apt-get install git-core build-essential libssl-dev libncurses5-dev unzip gawk subversion mercurial


 -  Download source tree from OpenWRT 15.05 branch

        $ cd src
        $ git clone git://git.openwrt.org/15.05/openwrt.git


 -  Download and install OpenWRT packages

        $ cd openwrt
        $ ./scripts/feeds update -a
        $ ./scripts/feeds install -a


 -  Apply patch

        $ cp ../../patches/openwrt/bluetooth_6lowpand_5.30-1.patch feeds/packages/
        $ cd feeds/packages/
        $ git apply bluetooth_6lowpand_5.30-1.patch
        $ cd ../../


 -  Configure build options in menuconfig

        $ make menuconfig
        Select Target System, Target Profile according to your OpenWRT hardware.
        (For example, select Atheros AR7xxx/AR9XXX for TP-Link Archer C7 router)
        - Global build settings ---> Uncheck Cryptographically Signed package lists
        - Utilities ---> Check bluez-utils
        Exit and Save settings


 -  Build Bluez-util package

        $ make tools/install
        $ make toolchain/install
        $ make package/feeds/packages/bluez/compile -j4
        $ make package/feeds/packages/bluez/install
        $ make package/index

        The package will be generated at bin/XXX/packages/packages/bluez-utils_5.30-1_XXX.ipk,
        XXX is the target system name.
        (For example, bin/ar71xx/packages/packages/bluez-utils_5.30-1_ar71xx.ipk)

##### Router part:

 -  Download and install the OpenWRT image from Chaos Calmer 15.05:

        https://downloads.openwrt.org/chaos_calmer/15.05/


 -  Login to the router and install the related packages:

        $ opkg update
        $ opkg install kmod-bluetooth kmod-bluetooth_6lowpan kmod-usb-ohci


 -  Copy the bluez-utils_5.30-1_XXX.ipk file into the router and Install the bluez-util package:

        $ opkg install --force-checksum bluez-utils_5.30-1_XXX.ipk
        (XXX depends on the hardware of OpenWRT router)	

How to use
===================================================

Below there is a couple of user-scenarios that are presented as a quick examples:

### Using the daemon for commissioning with manually set SSID and Passphrase

To run bluetooth_6lowpand daemon with SSID = 6LoWPAN and Passphrase = 123456 we can
execute below command.

    $ bluetooth_6lowpand -a 6LoWPAN:123456 -d

To stop the daemon call below command:

    $ killall bluetooth_6lowpand

### Using the daemon for commissioning on an OpenWRT router with shared WiFi credentials.

To reuse the same SSID and Passphrase as for WiFi interface the following command has to
be issued:

    $ bluetooth_6lowpand -a -d

Internally daemon tries to read WiFi ssid and key by using UCI command:

    $ uci get wireless.@wifi-iface[0].ssid
    $ uci get wireless.@wifi-iface[1].key

Since now, SSID and password may be changed from the LuCi interface, without restarting
the daemon. On each connection UCI commands are called to obtain fresh credentials.

NOTE: Passphrase has to have minimum 6 ascii-digits format. However WiFi depends on
security mode need more that 6 characters. Because of that, any character after 6th one
is ignored, so it is possible to declare one like this: 6LoWPAN:12345678


### Using daemon in whitelist mode

The bluetooth_6lowpand daemon can also work in the alternative mode, where it simply scans
and connects only IPSP enabled nodes from the whitelist. The daemon provides commands to add and
remove Bluetooth Device Addresses to be connected to. The actual whitelist is placed in
/etc/config/bluetooth_6lowpand.conf. To enable this mode execute the command below:

    $ bluetooth_6lowpand -W -d

To add/remove a single address to/from the whitelist use following commands:

    $ bluetooth_6lowpand addwl 00:11:22:33:44:55
    $ bluetooth_6lowpand rmwl 00:11:22:33:44:55

To clear all addresses:

    $ bluetooth_6lowpand clearwl

To list the addresses that are already added in the whitelist:

    $ bluetooth_6lowpand lswl
    
### Using /etc/init.d bluetooth_6lowpand service

Since the /etc/init.d/bluetooth_6lowpand script is installed, it is possible to use
the script to start/stop the daemon. By default the script loads the bluetooth_6lowpan kernel
module, sets proper PSM/ENABLE value, restarts hci0 interface and kills the bluetoothd
daemon.

To start the daemon with manually given parameters:

    $ /etc/init.d/bluetooth_6lowpand start 6LoWPAN:123456

To start the daemon with parameters obtained from UCI interface - WiFi (OpenWRT):

    $ /etc/init.d/bluetooth_6lowpand start

To stop the daemon:

    $ /etc/init.d/bluetooth_6lowpand stop

To get the actual status of the daemon:

    $ service bluetooth_6lowpand status

### Adjusting connection parameters

The daemon will constantly scan for a new IPSP enabled devices. Scanning parameters can be adjusted
using following options:

    -t - scanning interval
    -w - scanning windows

To run scanning for 5 seconds with 10 second interval issue the following command:

    $ bluetooth_6lowpand -t 10 -w 5 [REST PARAMETERS]
