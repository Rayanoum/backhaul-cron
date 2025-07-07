#!/bin/bash

# GitHub repository URL
GITHUB_REPO="https://raw.githubusercontent.com/Rayanoum/backhaul-cron/main/install.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to download and run the latest version
run_latest_version() {
    echo -e "${YELLOW}Downloading the latest version...${NC}"
    
    temp_script=$(mktemp)
    if curl -s "$GITHUB_REPO" -o "$temp_script"; then
        chmod +x "$temp_script"
        exec "$temp_script"
    else
        echo -e "${RED}Failed to download the latest version.${NC}"
        exit 1
    fi
}

# Function to display the main menu
show_menu() {
    clear
    echo " "
    echo -e "${YELLOW}-------- Auto Restart Service Management --------${NC}"
    echo -e "${GREEN}t.me/Rayanoum${NC}"
    echo -e "${BLUE}https://github.com/Rayanoum/backhaul-cron${NC}"
    echo -e "${YELLOW}-------------------------------------------------${NC}"
    echo -e "1. Add automatic restart schedule"
    echo -e "2. Remove automatic restart schedule"
    echo -e "3. Restart services now"
    echo -e "4. Test script (dry run)"
    echo -e "5. Exit"
    echo -n "Please enter your choice [1-5]: "
}

# Function to check if services exist
check_services() {
    services=$(systemctl list-unit-files | grep "backhaul-" | awk '{print $1}')
    if [ -z "$services" ]; then
        echo -e "${RED}No backhaul services found!${NC}"
        return 1
    fi
    echo -e "${GREEN}Found services:${NC}"
    echo "$services"
    return 0
}

# Function to add cron job
add_cron() {
    echo -e "${YELLOW}=== Add Automatic Restart Schedule ===${NC}"
    
    if ! check_services; then
        return
    fi
    
    while true; do
        echo -n "Enter restart interval in minutes (e.g., 10, 30, 60): "
        read interval
        
        if [[ "$interval" =~ ^[0-9]+$ ]] && [ "$interval" -gt 0 ]; then
            break
        else
            echo -e "${RED}Invalid input. Please enter a positive number.${NC}"
        fi
    done
    
    temp_cron=$(mktemp)
    crontab -l > "$temp_cron" 2>/dev/null
    sed -i '/backhaul-cron/d' "$temp_cron"
    echo "*/$interval * * * * /bin/bash -c 'services=\$(systemctl list-unit-files | grep \"backhaul-\" | awk '\''{print \$1}'\''); [ -n \"\$services\" ] && systemctl restart \$services' # backhaul-cron" >> "$temp_cron"
    crontab "$temp_cron"
    rm "$temp_cron"
    
    echo -e "${GREEN}Automatic restart every $interval minutes has been scheduled.${NC}"
    echo -e "${YELLOW}Current crontab:${NC}"
    crontab -l
}

# Function to remove cron job
remove_cron() {
    echo -e "${YELLOW}=== Remove Automatic Restart Schedule ===${NC}"
    
    temp_cron=$(mktemp)
    crontab -l > "$temp_cron" 2>/dev/null
    
    if grep -q "backhaul-cron" "$temp_cron"; then
        sed -i '/backhaul-cron/d' "$temp_cron"
        crontab "$temp_cron"
        echo -e "${GREEN}Automatic restart schedule has been removed.${NC}"
    else
        echo -e "${YELLOW}No automatic restart schedule was found.${NC}"
    fi
    
    rm "$temp_cron"
    echo -e "${YELLOW}Current crontab:${NC}"
    crontab -l
}

# Function to restart services now
restart_now() {
    echo -e "${YELLOW}=== Restart Services Now ===${NC}"
    
    if check_services; then
        echo -e "${YELLOW}Restarting services...${NC}"
        systemctl restart $services
        echo -e "${GREEN}Services have been restarted.${NC}"
    fi
}

# Function to test the script
test_script() {
    echo -e "${YELLOW}=== Test Script (Dry Run) ===${NC}"
    
    if check_services; then
        echo -e "${YELLOW}The following command would be executed:${NC}"
        echo "systemctl restart $services"
        echo -e "${GREEN}Test completed successfully (no changes were made).${NC}"
    fi
}

# Main execution
if [ "$0" = "bash" ]; then
    # When running via bash <(curl ...)
    run_latest_version
else
    # When running directly
    while true; do
        show_menu
        read choice
        
        case $choice in
            1) add_cron ;;
            2) remove_cron ;;
            3) restart_now ;;
            4) test_script ;;
            5) echo -e "${GREEN}Exiting...${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
        esac
        
        echo -e "\nPress any key to continue..."
        read -n 1 -s
    done
fi
