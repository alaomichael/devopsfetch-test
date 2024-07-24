#!/bin/bash

# Helper Functions
calculate_max_widths() {
    local data="$1"
    local -n max_lengths=$2

    while IFS='|' read -r -a cols; do
        for i in "${!cols[@]}"; do
            [[ ${#cols[i]} -gt ${max_lengths[i]} ]] && max_lengths[i]=${#cols[i]}
        done
    done <<< "$data"
}

str_repeat() {
    local char="$1"
    local times="$2"
    printf "%${times}s" | tr ' ' "$char"
}

log_message() {
    local message="$1"
    echo "[INFO] $(date): $message"
}

# Display Ports
display_ports() {
    echo "****************************** ACTIVE PORTS AND SERVICES ******************************"
    
    # Capture all active ports and services
    ports_services=$(sudo ss -tunlp | awk 'NR>1 {print $1"|" $2"|" $3"|" $4"|" $5"|" $6"|" $7"|" $8}')

    # Determine maximum column widths
    max_lengths=(8 10 8 8 22 22 20 10)
    calculate_max_widths "$ports_services" max_lengths

    header="| Netid    | State       | Recv-Q   | Send-Q   | Local Address:Port           | Peer Address:Port            | Process              | Service     |"
    separator=$(printf "%s" "${max_lengths[@]}" | sed 's/[0-9]\+/\x0/;s/\x0/\x0-/' | tr -d '\x0')
    
    echo "$header"
    echo "$separator"
    
    if [ -n "$1" ]; then
        log_message "Displaying details for port $1"
        sudo ss -tunlp | grep ":$1 " | awk -v max0="${max_lengths[0]}" -v max1="${max_lengths[1]}" -v max2="${max_lengths[2]}" -v max3="${max_lengths[3]}" -v max4="${max_lengths[4]}" -v max5="${max_lengths[5]}" -v max6="${max_lengths[6]}" -v max7="${max_lengths[7]}" '
            { printf "| %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s |\n", max0, $1, max1, $2, max2, $3, max3, $4, max4, $5, max5, $6, max6, $7, max7, $8; }'
    else
        log_message "Listing all active ports and services:"
        sudo ss -tunlp | awk -v max0="${max_lengths[0]}" -v max1="${max_lengths[1]}" -v max2="${max_lengths[2]}" -v max3="${max_lengths[3]}" -v max4="${max_lengths[4]}" -v max5="${max_lengths[5]}" -v max6="${max_lengths[6]}" -v max7="${max_lengths[7]}" '
            NR > 1 { printf "| %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s |\n", max0, $1, max1, $2, max2, $3, max3, $4, max4, $5, max5, $6, max6, $7, max7, $8; }'
    fi
    echo "**************************************************************************************"
}

# Display Docker
display_docker() {
    echo "****************************** DOCKER STATUS ******************************"

    # Capture Docker Images and Containers information
    docker_images=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" | tail -n +2)
    docker_containers=$(docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | tail -n +2)

    # Calculate maximum column widths for Docker Images
    max_image_lengths=(20 20 50 20)
    calculate_max_widths "$docker_images" max_image_lengths

    # Calculate maximum column widths for Docker Containers
    max_container_lengths=(20 20 20 20)
    calculate_max_widths "$docker_containers" max_container_lengths

    # Print Docker Images
    echo "Docker Images:"
    printf "| %-*s | %-*s | %-*s | %-*s |\n" "${max_image_lengths[0]}" "REPOSITORY" "${max_image_lengths[1]}" "TAG" "${max_image_lengths[2]}" "IMAGE ID" "${max_image_lengths[3]}" "SIZE"
    printf "| %s | %s | %s | %s |\n" "$(str_repeat '-' "${max_image_lengths[0]}")" "$(str_repeat '-' "${max_image_lengths[1]}")" "$(str_repeat '-' "${max_image_lengths[2]}")" "$(str_repeat '-' "${max_image_lengths[3]}")"
    echo "$docker_images" | awk -v max0="${max_image_lengths[0]}" -v max1="${max_image_lengths[1]}" -v max2="${max_image_lengths[2]}" -v max3="${max_image_lengths[3]}" '
    {
        printf "| %-*s | %-*s | %-*s | %-*s |\n", max0, $1, max1, $2, max2, $3, max3, $4;
    }'
    echo ""

    # Print Docker Containers
    echo "Docker Containers:"
    printf "| %-*s | %-*s | %-*s | %-*s |\n" "${max_container_lengths[0]}" "NAMES" "${max_container_lengths[1]}" "IMAGE" "${max_container_lengths[2]}" "STATUS" "${max_container_lengths[3]}" "PORTS"
    printf "| %s | %s | %s | %s |\n" "$(str_repeat '-' "${max_container_lengths[0]}")" "$(str_repeat '-' "${max_container_lengths[1]}")" "$(str_repeat '-' "${max_container_lengths[2]}")" "$(str_repeat '-' "${max_container_lengths[3]}")"
    echo "$docker_containers" | awk -v max0="${max_container_lengths[0]}" -v max1="${max_container_lengths[1]}" -v max2="${max_container_lengths[2]}" -v max3="${max_container_lengths[3]}" '
    {
        printf "| %-*s | %-*s | %-*s | %-*s |\n", max0, $1, max1, $2, max2, $3, max3, $4;
    }'
    echo "***************************************************************************"
}

# Display Nginx
display_nginx() {
    echo "****************************** NGINX DOMAIN VALIDATION ******************************"

    # Capture Nginx configuration
    nginx_config=$(sudo nginx -T 2>/dev/null | awk '{print $0"|" $0}' | sed 's/|/ /')

    # Determine maximum column widths
    max_lengths=(20 10 50)
    calculate_max_widths "$nginx_config" max_lengths

    if [ -n "$1" ]; then
        log_message "Displaying Nginx configuration for domain $1"
        domain_config=$(echo "$nginx_config" | awk "/server_name $1/,/}/")
        if [ -z "$domain_config" ]; then
            echo "Domain $1 not found in Nginx configuration."
        else
            echo "$domain_config"
        fi
    else
        log_message "Listing all Nginx domains and their ports:"
        printf "| %-*s | %-*s | %-*s |\n" "${max_lengths[0]}" "DOMAIN" "${max_lengths[1]}" "PROXY" "${max_lengths[2]}" "CONFIGURATION FILE"
        printf "| %s | %s | %s |\n" "$(str_repeat '-' "${max_lengths[0]}")" "$(str_repeat '-' "${max_lengths[1]}")" "$(str_repeat '-' "${max_lengths[2]}")"
        echo "$nginx_config" | awk -v max0="${max_lengths[0]}" -v max1="${max_lengths[1]}" -v max2="${max_lengths[2]}" '
        /server_name/ {
            server_name = $2;
            getline;
            while ($0 !~ /}/) {
                if ($0 ~ /listen/) {
                    port = $2;
                    gsub(";", "", port);
                    proxy = $(NF-1);
                    getline;
                    printf "| %-*s | %-*s | %-*s |\n", max0, server_name, max1, proxy, max2, "/etc/nginx/sites-enabled/" server_name ".conf";
                }
                getline;
            }
        }'
    fi
    echo "****************************************************************************"
}

# Display Users
display_users() {
    echo "****************************** USER DETAILS ******************************"

    # Capture user details
    user_info=$(getent passwd | awk -F: '{print $1"|" $5"|" $6"|" $7}')
    login_info=$(last -w | awk '{print $1"|" $4" "$5" "$6" "$7" "$8" "$9" "$10}')

    # Determine maximum column widths for user details
    max_user_lengths=(15 20 20 20)
    calculate_max_widths "$user_info" max_user_lengths

    # Determine maximum column widths for login records
    max_login_lengths=(15 20 20 20)
    calculate_max_widths "$login_info" max_login_lengths

    # Print User Details
    printf "| %-*s | %-*s | %-*s | %-*s |\n" "${max_user_lengths[0]}" "Username" "${max_user_lengths[1]}" "Full Name" "${max_user_lengths[2]}" "Home Directory" "${max_user_lengths[3]}" "Shell"
    printf "| %s | %s | %s | %s |\n" "$(str_repeat '-' "${max_user_lengths[0]}")" "$(str_repeat '-' "${max_user_lengths[1]}")" "$(str_repeat '-' "${max_user_lengths[2]}")" "$(str_repeat '-' "${max_user_lengths[3]}")"
    echo "$user_info" | awk -v max0="${max_user_lengths[0]}" -v max1="${max_user_lengths[1]}" -v max2="${max_user_lengths[2]}" -v max3="${max_user_lengths[3]}" '
    {
        split($0, fields, "|");
        printf "| %-*s | %-*s | %-*s | %-*s |\n", max0, fields[1], max1, fields[2], max2, fields[3], max3, fields[4];
    }'
    echo ""

    # Print Login Records
    printf "| %-*s | %-*s | %-*s | %-*s |\n" "${max_login_lengths[0]}" "User" "${max_login_lengths[1]}" "Login Time" "${max_login_lengths[2]}" "Logout Time" "${max_login_lengths[3]}" "Duration"
    printf "| %s | %s | %s | %s |\n" "$(str_repeat '-' "${max_login_lengths[0]}")" "$(str_repeat '-' "${max_login_lengths[1]}")" "$(str_repeat '-' "${max_login_lengths[2]}")" "$(str_repeat '-' "${max_login_lengths[3]}")"
    echo "$login_info" | awk -v max0="${max_login_lengths[0]}" -v max1="${max_login_lengths[1]}" -v max2="${max_login_lengths[2]}" -v max3="${max_login_lengths[3]}" '
    {
        split($0, fields, "|");
        printf "| %-*s | %-*s | %-*s | %-*s |\n", max0, fields[1], max1, fields[2], max2, fields[3], max3, fields[4];
    }'
    echo "***************************************************************************"
}

# Display Time Range
display_time_range() {
    echo "****************************** TIME RANGE DETAILS ******************************"
    
    start_time="$1"
    end_time="$2"

    # Capture log or event records
    log_records=$(grep -E "^[0-9]{4}-[0-9]{2}-[0-9]{2}" /var/log/syslog | awk -v start="$start_time" -v end="$end_time" '$0 >= start && $0 <= end')

    # Determine maximum column widths
    max_time_lengths=(80)
    calculate_max_widths "$log_records" max_time_lengths

    # Print Log Records
    echo "Displaying records from $start_time to $end_time:"
    printf "| %-*s |\n" "${max_time_lengths[0]}" "Timestamp and Details"
    printf "| %s |\n" "$(str_repeat '-' "${max_time_lengths[0]}")"
    echo "$log_records" | awk -v max0="${max_time_lengths[0]}" '
    {
        printf "| %-*s |\n", max0, $0;
    }'
    echo "**************************************************************************"
}

# Monitor Mode
monitor_mode() {
    echo "****************************** MONITOR MODE ******************************"
    echo "Entering monitor mode. Press [CTRL+C] to exit."

    while true; do
        clear
        date
        echo ""

        display_ports
        display_docker
        display_nginx
        display_users

        sleep 60
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
        display_users
        ;;
    -t|--time)
        display_time_range "$2" "$3"
        ;;
    -m|--monitor)
        monitor_mode
        ;;
    -h|--help)
        echo "Usage: $0 [OPTIONS]"
        echo "Options:"
        echo "  -p, --port <port>        Display details for a specific port"
        echo "  -d, --docker             Display Docker images and containers"
        echo "  -n, --nginx [domain]     Display Nginx configuration, or for a specific domain"
        echo "  -u, --users              Display user details and login records"
        echo "  -t, --time <start> <end> Display logs within a specific time range"
        echo "  -m, --monitor            Monitor mode to display all sections periodically"
        echo "  -h, --help               Display this help message"
        ;;
    *)
        echo "Invalid option. Use -h or --help for usage information."
        ;;
esac



#!/bin/bash

# LOG_FILE="/var/log/devopsfetch.log"

# # Function to log messages
# log_message() {
#     echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
# }

# # Ensure we have the necessary permissions
# if [ "$EUID" -ne 0 ]; then 
#     echo "Please run as root"
#     exit 1
# fi

# # Function to display active ports and services
# display_ports() {
#     echo "****************************** ACTIVE PORTS AND SERVICES ******************************"
#     printf "| %-8s | %-10s | %-8s | %-8s | %-22s | %-22s | %-20s | %-10s |\n" "Netid" "State" "Recv-Q" "Send-Q" "Local Address:Port" "Peer Address:Port" "Process" "Service"
#     echo "----------------------------------------------------------------------------------------"
#     if [ -n "$1" ]; then
#         log_message "Displaying details for port $1"
#         sudo ss -tunlp | grep ":$1 " | awk '
#             { printf "| %-8s | %-10s | %-8s | %-8s | %-22s | %-22s | %-20s | %-10s |\n", $1, $2, $3, $4, $5, $6, $7, $8; }'
#     else
#         log_message "Listing all active ports and services:"
#         sudo ss -tunlp | awk '
#             NR > 1 {
#                 printf "| %-8s | %-10s | %-8s | %-8s | %-22s | %-22s | %-20s | %-10s |\n", $1, $2, $3, $4, $5, $6, $7, $8;
#             }'
#     fi
#     echo "**************************************************************************************"
# }

# # Function to display Docker images and containers
# display_docker() {
#     echo "****************************** DOCKER STATUS ******************************"
#     echo "Docker Images:"
#     printf "| %-20s | %-20s | %-50s | %-20s |\n" "REPOSITORY" "TAG" "IMAGE ID" "SIZE"
#     echo "---------------------------------------------------------------------------"
#     docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" | tail -n +2 | awk '
#         { printf "| %-20s | %-20s | %-50s | %-20s |\n", $1, $2, $3, $4; }'

#     echo ""
#     echo "Docker Containers:"
#     printf "| %-20s | %-20s | %-20s | %-20s |\n" "NAMES" "IMAGE" "STATUS" "PORTS"
#     echo "---------------------------------------------------------------------------"
#     docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | tail -n +2 | awk '
#         { printf "| %-20s | %-20s | %-20s | %-20s |\n", $1, $2, $3, $4; }'
#     echo "***************************************************************************"
# }

# # Function to display Nginx configurations
# display_nginx() {
#     echo "****************************** NGINX DOMAIN VALIDATION ******************************"
#     if [ -n "$1" ]; then
#         log_message "Displaying Nginx configuration for domain $1"
#         domain_config=$(sudo nginx -T 2>/dev/null | awk "/server_name $1/,/}/")
#         if [ -z "$domain_config" ]; then
#             echo "Domain $1 not found in Nginx configuration."
#         else
#             echo "$domain_config"
#         fi
#     else
#         log_message "Listing all Nginx domains and their ports:"
#         printf "| %-20s | %-10s | %-50s |\n" "DOMAIN" "PROXY" "CONFIGURATION FILE"
#         echo "----------------------------------------------------------------------------"
#         sudo nginx -T 2>/dev/null | awk '
#             /server_name/ {
#                 server_name = $2;
#                 getline;
#                 while ($0 !~ /}/) {
#                     if ($0 ~ /listen/) {
#                         port = $2;
#                         gsub(";", "", port);
#                         proxy = $(NF-1);
#                         getline;
#                         printf "| %-20s | %-10s | %-50s |\n", server_name, proxy, "/etc/nginx/sites-enabled/" server_name ".conf";
#                     }
#                     getline;
#                 }
#             }'
#     fi
#     echo "****************************************************************************"
# }

# # Function to display user logins and details
# display_users() {
#     echo "****************************** USER DETAILS ******************************"
#     if [ -n "$1" ]; then
#         log_message "Displaying user details and login records for $1"
#         printf "| %-15s | %-20s | %-20s | %-20s |\n" "Username" "Full Name" "Home Directory" "Shell"
#         echo "--------------------------------------------------------------------------"
        
#         # Fetch user details
#         user_info=$(getent passwd "$1" | awk -F: '{ printf "| %-15s | %-20s | %-20s | %-20s |\n", $1, $5, $6, $7 }')
#         if [ -n "$user_info" ]; then
#             echo "$user_info"
            
#             echo ""
#             printf "| %-15s | %-10s | %-20s | %-20s |\n" "Username" "Terminal" "Login Time" "Session Duration"
#             echo "--------------------------------------------------------------------------"
#             last -w "$1" | head -n -2 | awk '{ printf "| %-15s | %-10s | %-20s | %-20s |\n", $1, $2, $4" "$5" "$6, $7 }'
#         else
#             echo "No such user: $1"
#         fi
#     else
#         log_message "Listing all users and their last login times"
#         printf "| %-15s | %-20s | %-20s | %-20s |\n" "Username" "Full Name" "Home Directory" "Shell"
#         echo "--------------------------------------------------------------------------"
        
#         # List all users
#         awk -F: '{ printf "| %-15s | %-20s | %-20s | %-20s |\n", $1, $5, $6, $7 }' /etc/passwd
        
#         echo ""
#         printf "| %-15s | %-10s | %-20s | %-20s |\n" "Username" "Terminal" "Login Time" "Session Duration"
#         echo "--------------------------------------------------------------------------"
#         for user in $(awk -F: '{print $1}' /etc/passwd); do
#             last -w "$user" | head -n -2 | awk -v user="$user" 'NR > 1 { printf "| %-15s | %-10s | %-20s | %-20s |\n", user, $2, $4" "$5" "$6, $7 }'
#         done
#     fi
#     echo "**************************************************************************"
# }

# # Function to display activities within a specified time range
# display_time_range() {
#     echo "****************************** ACTIVITY LOG ******************************"
#     if [ -z "$1" ] || [ -z "$2" ]; then
#         echo "Please specify both start and end times in the format YYYY-MM-DD HH:MM:SS"
#         return
#     fi
#     start_time=$1
#     end_time=$2
#     log_message "Displaying activities from $start_time to $end_time"
#     printf "| %-15s | %-10s | %-20s | %-20s |\n" "Username" "Terminal" "Login Time" "Session Duration"
#     echo "--------------------------------------------------------------------------"
#     last -w | awk -v start="$start_time" -v end="$end_time" '
#         $4 " " $5 " " $6 >= start && $4 " " $5 " " $6 <= end {
#             printf "| %-15s | %-10s | %-20s | %-20s |\n", $1, $2, $4" "$5" "$6, $7
#         }'
#     echo "**************************************************************************"
# }

# # Function to display help
# display_help() {
#     echo "Usage: $0 [option]"
#     echo "Options:"
#     echo "  -p, --port [port_number]         Display active ports and services, or details for a specific port"
#     echo "  -d, --docker [container_name]    List Docker images and containers, or details for a specific container"
#     echo "  -n, --nginx [domain]             Display Nginx domains and ports, or configuration for a specific domain"
#     echo "  -u, --users [username]           List users and last login times, or details for a specific user"
#     echo "  -t, --time [start_time] [end_time] Display activities within a specified time range"
#     echo "  -m, --monitor                    Start monitoring mode"
#     echo "  -h, --help                       Display this help message"
# }

# # Function for monitoring mode
# monitor_mode() {
#     log_message "Monitoring mode started"
#     while true; do
#         log_message "Logging active ports and services:"
#         display_ports | tee -a "$LOG_FILE"
        
#         log_message "Logging Docker images and containers:"
#         display_docker | tee -a "$LOG_FILE"
        
#         log_message "Logging Nginx domains and ports:"
#         display_nginx | tee -a "$LOG_FILE"
        
#         log_message "Logging users and last login times:"
#         display_users | tee -a "$LOG_FILE"
        
#         log_message "Logging completed. Waiting for the next interval..."
#         sleep 3600 # Wait for 1 hour before repeating
#     done
# }

# # Parse command-line options
# case "$1" in
#     -p|--port)
#         display_ports "$2"
#         ;;
#     -d|--docker)
#         display_docker "$2"
#         ;;
#     -n|--nginx)
#         display_nginx "$2"
#         ;;
#     -u|--users)
#         display_users "$2"
#         ;;
#     -t|--time)
#         display_time_range "$2" "$3"
#         ;;
#     -m|--monitor)
#         monitor_mode
#         ;;
#     -h|--help)
#         display_help
#         ;;
#     *)
#         display_help
#         ;;
# esac
