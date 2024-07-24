#!/bin/bash

LOG_FILE="/var/log/devopsfetch.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to display Docker information
display_docker() {
    if [ -n "$1" ]; then
        log_message "Displaying details for Docker container $1"
        container_info=$(docker inspect "$1")
        if [ -n "$container_info" ]; then
            printf "%-15s %-50s\n" "Field" "Value"
            echo "$container_info" | jq -r '.[] | to_entries[] | [.key, .value] | @tsv' | while IFS=$'\t' read -r key value; do
                printf "%-15s %-50s\n" "$key" "$value"
            done
        else
            echo "No such container: $1"
        fi
    else
        log_message "Listing all Docker images and containers:"
        
        echo "**********************  DOCKER STATUS  **********************"
        echo "Docker Images:"
        printf "| %-20s | %-20s | %-15s | %-10s |\n" "REPOSITORY" "TAG" "IMAGE ID" "SIZE"
        docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" | tail -n +2 | while IFS=$'\t' read -r repo tag id size; do
            printf "| %-20s | %-20s | %-15s | %-10s |\n" "$repo" "$tag" "$id" "$size"
        done
        
        echo ""
        echo "Docker Containers:"
        printf "| %-25s | %-20s | %-10s | %-10s |\n" "NAMES" "IMAGE" "STATUS" "PORTS"
        docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | tail -n +2 | while IFS=$'\t' read -r names image status ports; do
            printf "| %-25s | %-20s | %-10s | %-10s |\n" "$names" "$image" "$status" "$ports"
        done
    fi
}

# Function to display Nginx information
display_nginx() {
    if [ -n "$1" ]; then
        log_message "Displaying details for Nginx domain $1"
        config_file=$(grep -r "server_name.*$1" /etc/nginx/sites-available /etc/nginx/sites-enabled | awk -F: '{print $1}' | uniq)
        if [ -n "$config_file" ]; then
            printf "%-10s %-50s\n" "Field" "Value"
            echo "Port: $(grep -Eo 'listen [0-9]+' $config_file | awk '{print $2}')"
            echo "Root: $(grep -Eo 'root .+' $config_file | awk '{print $2}')"
            echo "Index: $(grep -Eo 'index .+' $config_file | awk '{print $2}')"
            echo "Server Name: $1"
            echo "Configuration File: $config_file"
        else
            echo "No such domain: $1"
        fi
    else
        log_message "Listing all Nginx domains and their ports:"
        echo "**********************  NGINX DOMAIN VALIDATION  **********************"
        printf "| %-30s | %-30s | %-30s |\n" "DOMAIN" "PROXY" "CONFIGURATION FILE"
        grep -r 'server_name' /etc/nginx/sites-available /etc/nginx/sites-enabled | awk -F: '{print $2, $1}' | sed 's/server_name//' | while read -r domain config; do
            proxy=$(grep -Eo 'proxy_pass .+' $config | awk '{print $2}' | tr '\n' ' ')
            printf "| %-30s | %-30s | %-30s |\n" "$domain" "${proxy:-<No Proxy>}" "$config"
        done
    fi
}

# Function to display user logins and details
display_users() {
    if [ -n "$1" ]; then
        log_message "Displaying user details and login records for $1"
        printf "%-15s %-20s %-20s %-20s\n" "Username" "Full Name" "Home Directory" "Shell"
        user_info=$(getent passwd "$1" | awk -F: '{ printf "%-15s %-20s %-20s %-20s\n", $1, $5, $6, $7 }')
        if [ -n "$user_info" ]; then
            echo "$user_info"
            printf "\n%-15s %-10s %-20s %-20s\n" "Username" "Terminal" "Login Time" "Session Duration"
            last -w "$1" | head -n -2 | awk '{ printf "%-15s %-10s %-20s %-20s\n", $1, $2, $4" "$5" "$6, $7 }'
        else
            echo "No such user: $1"
        fi
    else
        log_message "Listing all users and their last login times"
        echo "**********************  USER INFORMATION  **********************"
        printf "| %-15s | %-20s | %-20s | %-20s |\n" "Username" "Full Name" "Home Directory" "Shell"
        awk -F: '{ printf "| %-15s | %-20s | %-20s | %-20s |\n", $1, $5, $6, $7 }' /etc/passwd
        
        echo ""
        printf "| %-15s | %-10s | %-20s | %-20s |\n" "Username" "Terminal" "Login Time" "Session Duration"
        for user in $(awk -F: '{print $1}' /etc/passwd); do
            last -w "$user" | head -n -2 | awk -v user="$user" 'NR > 1 { printf "| %-15s | %-10s | %-20s | %-20s |\n", user, $2, $4" "$5" "$6, $7 }'
        done
    fi
}

# Function to display activities within a specified time range
display_time_range() {
    if [ -n "$1" ]; then
        log_message "Displaying activities from $1 to $2"
        printf "%-20s %-20s %-50s\n" "Time" "Service" "Description"
        journalctl --since="$1" --until="$2" | awk '{ printf "%-20s %-20s %-50s\n", $1" "$2, $3, substr($0, index($0,$4)) }'
    else
        echo "Please provide a time range."
    fi
}

# Main function
case "$1" in
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
    *)
        echo "Usage: $0 {-d|--docker [container_name]} {-n|--nginx [domain]} {-u|--users [username]} {-t|--time <start_time> <end_time>}"
        ;;
esac
