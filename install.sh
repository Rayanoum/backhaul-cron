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
    echo -e "${YELLOW}────────────────────────────────────────────────────${NC}"
}

# Function to display the main menu
show_menu() {
    show_header
    echo -e "   ${GREEN}1. Add or Edit automatic restart schedule${NC}"
    echo -e "   ${GREEN}2. Remove automatic restart schedule${NC}"
    echo -e "   ${GREEN}3. Restart services now${NC}"
    echo -e "   ${RED}4. Exit${NC}"
    echo -e "${YELLOW}────────────────────────────────────────────────────${NC}"
    echo -n "   Please enter your choice [1-4]: "
}

# Function to check if services exist
check_services() {
    services=$(systemctl list-unit-files | grep "backhaul-" | awk '{print $1}')
    if [ -z "$services" ]; then
        echo -e "\n${RED}✖ No backhaul services found!${NC}\n"
        return 1
    fi
    echo -e "   ${GREEN}✔ Found services:${NC}"
    # Process each service with consistent indentation
    while IFS= read -r service; do
        echo -e "     ${CYAN}$service${NC}"
    done <<< "$services"
    echo -ne "\n"  # Only one newline after services list
    return 0
}

# Function to check if cron job exists
check_cron_exists() {
    crontab -l 2>/dev/null | grep -q "systemctl list-unit-files | grep \"backhaul-\""
    return $?
}

# Function to get current cron interval
get_current_cron_interval() {
    crontab -l 2>/dev/null | grep "systemctl list-unit-files | grep \"backhaul-\"" | sed -n 's|^\*/\([0-9]*\) \* \* \* \* .*|\1|p'
}

# Function to add/edit cron job
add_cron() {
    show_header
    echo -e "       ${YELLOW}════════ Add/Edit Restart Schedule ═════════${NC}"
    # Check if cron job already exists
    if check_cron_exists; then
        current_interval=$(get_current_cron_interval)
        echo -e " ${GREEN}✓ Existing cron job found with interval: ${current_interval} minutes${NC}"
        echo -e " ${YELLOW}This will edit the existing schedule.${NC}\n"
    fi
    if ! check_services; then
        return
    fi
    while true; do
        echo -ne " ${GREEN}Enter restart interval in minutes (1-59): ${NC}"
        read interval
        if [[ "$interval" =~ ^[0-9]+$ ]] && [ "$interval" -ge 1 ] && [ "$interval" -le 59 ]; then
            break
        else
            echo -e "${RED}Invalid input. Please enter a number between 1 and 59.${NC}"
        fi
    done
    temp_cron=$(mktemp)
    crontab -l > "$temp_cron" 2>/dev/null
    # Remove any existing backhaul restart cron
    sed -i '/systemctl list-unit-files | grep "backhaul-"/d' "$temp_cron"
    echo "*/$interval * * * * /bin/bash -c 'services=\$(systemctl list-unit-files | grep \"backhaul-\" | awk '\''{print \$1}'\''); [ -n \"\$services\" ] && systemctl restart \$services'" >> "$temp_cron"
    crontab "$temp_cron"
    rm "$temp_cron"
    if check_cron_exists; then
        echo -e "\n ${GREEN}✓ Automatic restart schedule updated to every $interval minutes.${NC}"
    else
        echo -e "\n ${GREEN}✓ Automatic restart every $interval minutes has been scheduled.${NC}"
    fi
}

# Function to remove cron job
remove_cron() {
    show_header
    echo -e "       ${RED}══════ Remove Restart Schedule ════════${NC}"
    if check_cron_exists; then
        current_interval=$(get_current_cron_interval)
        temp_cron=$(mktemp)
        crontab -l > "$temp_cron" 2>/dev/null
        sed -i '/systemctl list-unit-files | grep "backhaul-"/d' "$temp_cron"
        crontab "$temp_cron"
        rm "$temp_cron"
        echo -e "\n ${GREEN}✓ Automatic restart schedule (every $current_interval minutes) has been removed.${NC}"
    else
        echo -e "\n ${RED}No automatic restart schedule was found.${NC}"
    fi
}

# Function to restart services now
restart_now() {
    show_header
    echo -e "       ${YELLOW}════════ Restart Services Now ═════════${NC}\n"
    if check_services; then
        echo -e "   ${YELLOW}Restarting services...${NC}\n"
        systemctl restart $services
        echo -e " ${GREEN}✓ Services have been restarted.${NC}"
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
            echo -e "${GREEN}Exiting...${NC}"
            sleep 1
            clear
            exit 0 
            ;;
        *) 
            echo -e "\n ${RED}Invalid option. Please try again.${NC}"
            ;;
    esac
    echo -e "\n ${BLUE}Press any key to return to menu...${NC}"
    read -n 1 -s
done
# https://github.com/Rayanoum/backhaul-cron
# t.me/Rayanoum
