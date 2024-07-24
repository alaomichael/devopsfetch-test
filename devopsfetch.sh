#!/bin/bash

LOG_FILE="/var/log/devopsfetch.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Ensure we have the necessary permissions
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Function to display active ports and services
display_ports() {
    echo "****************************** ACTIVE PORTS AND SERVICES ******************************"
    printf "| %-8s | %-10s | %-8s | %-8s | %-22s | %-22s | %-20s | %-10s |\n" "Netid" "State" "Recv-Q" "Send-Q" "Local Address:Port" "Peer Address:Port" "Process" "Service"
    echo "----------------------------------------------------------------------------------------"
    if [ -n "$1" ]; then
        log_message "Displaying details for port $1"
        sudo ss -tunlp | grep ":$1 " | awk '
            { printf "| %-8s | %-10s | %-8s | %-8s | %-22s | %-22s | %-20s | %-10s |\n", $1, $2, $3, $4, $5, $6, $7, $8; }'
    else
        log_message "Listing all active ports and services:"
        sudo ss -tunlp | awk '
            NR > 1 {
                printf "| %-8s | %-10s | %-8s | %-8s | %-22s | %-22s | %-20s | %-10s |\n", $1, $2, $3, $4, $5, $6, $7, $8;
            }'
    fi
    echo "**************************************************************************************"
}

# Function to display Docker images and containers
display_docker() {
    echo "****************************** DOCKER STATUS ******************************"
    echo "Docker Images:"
    printf "| %-20s | %-20s | %-50s | %-20s |\n" "REPOSITORY" "TAG" "IMAGE ID" "SIZE"
    echo "---------------------------------------------------------------------------"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" | tail -n +2 | awk '
        { printf "| %-20s | %-20s | %-50s | %-20s |\n", $1, $2, $3, $4; }'

    echo ""
    echo "Docker Containers:"
    printf "| %-20s | %-20s | %-20s | %-20s |\n" "NAMES" "IMAGE" "STATUS" "PORTS"
    echo "---------------------------------------------------------------------------"
    docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | tail -n +2 | awk '
        { printf "| %-20s | %-20s | %-20s | %-20s |\n", $1, $2, $3, $4; }'
    echo "***************************************************************************"
}

# Function to display Nginx configurations
display_nginx() {
    echo "****************************** NGINX DOMAIN VALIDATION ******************************"
    if [ -n "$1" ]; then
        log_message "Displaying Nginx configuration for domain $1"
        domain_config=$(sudo nginx -T 2>/dev/null | awk "/server_name $1/,/}/")
        if [ -z "$domain_config" ]; then
            echo "Domain $1 not found in Nginx configuration."
        else
            echo "$domain_config"
        fi
    else
        log_message "Listing all Nginx domains and their ports:"
        printf "| %-20s | %-10s | %-50s |\n" "DOMAIN" "PROXY" "CONFIGURATION FILE"
        echo "----------------------------------------------------------------------------"
        sudo nginx -T 2>/dev/null | awk '
            /server_name/ {
                server_name = $2;
                getline;
                while ($0 !~ /}/) {
                    if ($0 ~ /listen/) {
                        port = $2;
                        gsub(";", "", port);
                        proxy = $(NF-1);
                        getline;
                        printf "| %-20s | %-10s | %-50s |\n", server_name, proxy, "/etc/nginx/sites-enabled/" server_name ".conf";
                    }
                    getline;
                }
            }'
    fi
    echo "****************************************************************************"
}

# Function to display user logins and details
display_users() {
    echo "****************************** USER DETAILS ******************************"
    if [ -n "$1" ]; then
        log_message "Displaying user details and login records for $1"
        printf "| %-15s | %-20s | %-20s | %-20s |\n" "Username" "Full Name" "Home Directory" "Shell"
        echo "--------------------------------------------------------------------------"
        
        # Fetch user details
        user_info=$(getent passwd "$1" | awk -F: '{ printf "| %-15s | %-20s | %-20s | %-20s |\n", $1, $5, $6, $7 }')
        if [ -n "$user_info" ]; then
            echo "$user_info"
            
            echo ""
            printf "| %-15s | %-10s | %-20s | %-20s |\n" "Username" "Terminal" "Login Time" "Session Duration"
            echo "--------------------------------------------------------------------------"
            last -w "$1" | head -n -2 | awk '{ printf "| %-15s | %-10s | %-20s | %-20s |\n", $1, $2, $4" "$5" "$6, $7 }'
        else
            echo "No such user: $1"
        fi
    else
        log_message "Listing all users and their last login times"
        printf "| %-15s | %-20s | %-20s | %-20s |\n" "Username" "Full Name" "Home Directory" "Shell"
        echo "--------------------------------------------------------------------------"
        
        # List all users
        awk -F: '{ printf "| %-15s | %-20s | %-20s | %-20s |\n", $1, $5, $6, $7 }' /etc/passwd
        
        echo ""
        printf "| %-15s | %-10s | %-20s | %-20s |\n" "Username" "Terminal" "Login Time" "Session Duration"
        echo "--------------------------------------------------------------------------"
        for user in $(awk -F: '{print $1}' /etc/passwd); do
            last -w "$user" | head -n -2 | awk -v user="$user" 'NR > 1 { printf "| %-15s | %-10s | %-20s | %-20s |\n", user, $2, $4" "$5" "$6, $7 }'
        done
    fi
    echo "**************************************************************************"
}

# Function to display activities within a specified time range
display_time_range() {
    echo "****************************** ACTIVITY LOG ******************************"
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Please specify both start and end times in the format YYYY-MM-DD HH:MM:SS"
        return
    fi
    start_time=$1
    end_time=$2
    log_message "Displaying activities from $start_time to $end_time"
    printf "| %-15s | %-10s | %-20s | %-20s |\n" "Username" "Terminal" "Login Time" "Session Duration"
    echo "--------------------------------------------------------------------------"
    last -w | awk -v start="$start_time" -v end="$end_time" '
        $4 " " $5 " " $6 >= start && $4 " " $5 " " $6 <= end {
            printf "| %-15s | %-10s | %-20s | %-20s |\n", $1, $2, $4" "$5" "$6, $7
        }'
    echo "**************************************************************************"
}

# Function to display help
display_help() {
    echo "Usage: $0 [option]"
    echo "Options:"
    echo "  -p, --port [port_number]         Display active ports and services, or details for a specific port"
    echo "  -d, --docker [container_name]    List Docker images and containers, or details for a specific container"
    echo "  -n, --nginx [domain]             Display Nginx domains and ports, or configuration for a specific domain"
    echo "  -u, --users [username]           List users and last login times, or details for a specific user"
    echo "  -t, --time [start_time] [end_time] Display activities within a specified time range"
    echo "  -m, --monitor                    Start monitoring mode"
    echo "  -h, --help                       Display this help message"
}

# Function for monitoring mode
monitor_mode() {
    log_message "Monitoring mode started"
    while true; do
        log_message "Logging active ports and services:"
        display_ports | tee -a "$LOG_FILE"
        
        log_message "Logging Docker images and containers:"
        display_docker | tee -a "$LOG_FILE"
        
        log_message "Logging Nginx domains and ports:"
        display_nginx | tee -a "$LOG_FILE"
        
        log_message "Logging users and last login times:"
        display_users | tee -a "$LOG_FILE"
        
        log_message "Logging completed. Waiting for the next interval..."
        sleep 3600 # Wait for 1 hour before repeating
    done
}

# Parse command-line options
case "$1" in
    -p|--port)
        display_ports "$2"
        ;;
    -d|--docker)
        display_docker "$2"
        ;;
    -n|--nginx)
        display_nginx "$2"
        ;;
    -u|--users)
        display_users "$2"
        ;;
    -t|--time)
        display_time_range "$2" "$3"
        ;;
    -m|--monitor)
        monitor_mode
        ;;
    -h|--help)
        display_help
        ;;
    *)
        display_help
        ;;
esac
