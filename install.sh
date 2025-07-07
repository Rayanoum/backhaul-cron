#!/bin/bash

# Current installed version
INSTALLED_VERSION="1.3.0"

# GitHub repository URL
GITHUB_SCRIPT_URL="https://raw.githubusercontent.com/Rayanoum/backhaul-cron/main/install.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check and update script
check_and_update() {
    echo -e "${YELLOW}Checking for updates...${NC}"
    
    # Download the script temporarily
    TEMP_SCRIPT=$(mktemp)
    if ! curl -s "$GITHUB_SCRIPT_URL" -o "$TEMP_SCRIPT"; then
        echo -e "${RED}Failed to check for updates. Continuing with current version.${NC}"
        rm -f "$TEMP_SCRIPT"
        return 1
    fi

    # Extract version from GitHub script
    ONLINE_VERSION=$(grep -m1 'INSTALLED_VERSION=' "$TEMP_SCRIPT" | cut -d'"' -f2)
    
    if [ -z "$ONLINE_VERSION" ]; then
        echo -e "${YELLOW}Could not determine online version. Continuing with current version.${NC}"
        rm -f "$TEMP_SCRIPT"
        return 1
    fi

    if [ "$INSTALLED_VERSION" != "$ONLINE_VERSION" ]; then
        echo -e "${GREEN}New version available ($ONLINE_VERSION), updating...${NC}"
        
        # Get script path
        SCRIPT_PATH=$(realpath "$0")
        
        # Create backup
        cp "$SCRIPT_PATH" "${SCRIPT_PATH}.bak"
        
        # Replace with new version
        if mv "$TEMP_SCRIPT" "$SCRIPT_PATH" && chmod +x "$SCRIPT_PATH"; then
            echo -e "${GREEN}Successfully updated to version $ONLINE_VERSION${NC}"
            echo -e "${YELLOW}Restarting script...${NC}"
            exec "$SCRIPT_PATH"
            exit 0
        else
            echo -e "${RED}Update failed! Continuing with current version.${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}You have the latest version ($INSTALLED_VERSION).${NC}"
        rm -f "$TEMP_SCRIPT"
    fi
}

# Function to display the main menu
show_menu() {
    clear
    echo " "
    echo -e "${YELLOW}-------- Auto Restart Service Management --------${NC}"
    echo -e "${BLUE}Version: ${INSTALLED_VERSION}${NC}"
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
check_and_update

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
