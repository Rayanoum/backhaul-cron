#!/bin/bash

# Script version
SCRIPT_VERSION="1.0.2"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display header
show_header() {
    clear
    echo -e "${PURPLE}"
    echo "      ╔══════════════════════════════════════════╗"
    echo "      ║    Auto Restart Service Management       ║"
    echo "      ╚══════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "   ${CYAN}Version: ${SCRIPT_VERSION}${NC}"
    echo -e "   ${BLUE}t.me/dev_spaceX${NC}"
    echo -e "   ${BLUE}github.com/Rayanoum/backhaul-cron${NC}"
    echo -e "${YELLOW}───────────────────────────────────────────${NC}"
}

# Function to display the main menu
show_menu() {
    show_header
    echo -e "   ${GREEN}1. Add or Edit automatic restart schedule${NC}"
    echo -e "   ${GREEN}2. Remove automatic restart schedule${NC}"
    echo -e "   ${GREEN}3. Restart services now${NC}"
    echo -e "   ${RED}4. Exit${NC}"
    echo -e "${YELLOW}───────────────────────────────────────────${NC}"
    echo -n "   Please enter your choice [1-4]: "
}

# Function to check if services exist
check_services() {
    services=$(systemctl list-unit-files | grep "backhaul-" | awk '{print $1}')
    if [ -z "$services" ]; then
        echo -e "\n ${RED}✖ No backhaul services found!${NC}"
        return 1
    fi
    echo -e "\n ${GREEN}✔ Found services:${NC}"
    echo -e "${CYAN}$services${NC}"
    return 0
}

# Function to add cron job
add_cron() {
    show_header
    echo -e "       ${YELLOW}════════ Add Restart Schedule ═════════${NC}"
    if ! check_services; then
        return
    fi
    while true; do
        echo -ne "\n ${GREEN}Enter restart interval in minutes (e.g., 10, 30, 60): ${NC}"
        read interval
        if [[ "$interval" =~ ^[0-9]+$ ]] && [ "$interval" -gt 0 ]; then
            break
        else
            echo -e " ${RED}Invalid input. Please enter a positive number.${NC}"
        fi
    done
    temp_cron=$(mktemp)
    crontab -l > "$temp_cron" 2>/dev/null
    sed -i '/backhaul-cron/d' "$temp_cron"
    echo "*/$interval * * * * /bin/bash -c 'services=\$(systemctl list-unit-files | grep \"backhaul-\" | awk '\''{print \$1}'\''); [ -n \"\$services\" ] && systemctl restart \$services' # backhaul-cron" >> "$temp_cron"
    crontab "$temp_cron"
    rm "$temp_cron"
    echo -e "\n ${GREEN}✓ Automatic restart every $interval minutes has been scheduled.${NC}"
    echo -e "\n ${YELLOW}Current crontab:${NC}"
    crontab -l
}

# Function to remove cron job
remove_cron() {
    show_header
    echo -e "       ${RED}══════ Remove Restart Schedule ════════${NC}"
    temp_cron=$(mktemp)
    crontab -l > "$temp_cron" 2>/dev/null
    if grep -q "backhaul-cron" "$temp_cron"; then
        sed -i '/backhaul-cron/d' "$temp_cron"
        crontab "$temp_cron"
        echo -e "\n ${GREEN}✓ Automatic restart schedule has been removed.${NC}"
    else
        echo -e "\n ${RED}No automatic restart schedule was found.${NC}"
    fi
    rm "$temp_cron"
    echo -e "\n ${RED}Current crontab:${NC}"
    crontab -l
}

# Function to restart services now
restart_now() {
    show_header
    echo -e "       ${YELLOW}════════ Restart Services Now ═════════${NC}"
    if check_services; then
        echo -e "\n ${YELLOW}Restarting services...${NC}"
        systemctl restart $services
        echo -e "\n ${GREEN}✓ Services have been restarted.${NC}"
    fi
}

# Main execution
while true; do
    show_menu
    read choice
    case $choice in
        1) add_cron ;;
        2) remove_cron ;;
        3) restart_now ;;
        4) 
            echo -e " ${GREEN}Exiting...${NC}"
            exit 0 
            ;;
        *) 
            echo -e "\n ${RED}Invalid option. Please try again.${NC}"
            ;;
    esac
    echo -e "\n ${BLUE}Press any key to return to menu...${NC}"
    read -n 1 -s
done
