#!/bin/bash

LOG_FILE="/var/log/devopsfetch.log"

# Function to repeat characters
str_repeat() {
    local char="$1"
    local count="$2"
    printf "%${count}s" | tr ' ' "$char"
}

# Function to calculate maximum column widths
calculate_max_widths() {
    local data="$1"
    local -n widths_ref="$2"
    
    # Initialize widths to 0
    for i in "${!widths_ref[@]}"; do
        widths_ref[$i]=0
    done

    # Calculate max widths
    echo "$data" | while IFS='|' read -r -a fields; do
        for i in "${!fields[@]}"; do
            local len=${#fields[$i]}
            if (( len > widths_ref[i] )); then
                widths_ref[i]=$len
            fi
        done
    done
}

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
    
    # Extract and format active ports and services
    local ports_info
    ports_info=$(netstat -tuln 2>/dev/null | awk 'NR>2 {print $1"|" $6"|" $5"|" $4"|" $7"|" $9}')
    
    # Determine maximum column widths for ports info
    local max_ports_lengths=(10 10 15 15 30 30)
    calculate_max_widths "$ports_info" max_ports_lengths

    # Print Ports and Services
    printf "| %-*s | %-*s | %-*s | %-*s | %-*s | %-*s |\n" "${max_ports_lengths[0]}" "Netid" "${max_ports_lengths[1]}" "State" "${max_ports_lengths[2]}" "Recv-Q" "${max_ports_lengths[3]}" "Send-Q" "${max_ports_lengths[4]}" "Local Address:Port" "${max_ports_lengths[5]}" "Peer Address:Port"
    printf "| %s | %s | %s | %s | %s | %s |\n" "$(str_repeat '-' "${max_ports_lengths[0]}")" "$(str_repeat '-' "${max_ports_lengths[1]}")" "$(str_repeat '-' "${max_ports_lengths[2]}")" "$(str_repeat '-' "${max_ports_lengths[3]}")" "$(str_repeat '-' "${max_ports_lengths[4]}")" "$(str_repeat '-' "${max_ports_lengths[5]}")"
    echo "$ports_info" | awk -v max0="${max_ports_lengths[0]}" -v max1="${max_ports_lengths[1]}" -v max2="${max_ports_lengths[2]}" -v max3="${max_ports_lengths[3]}" -v max4="${max_ports_lengths[4]}" -v max5="${max_ports_lengths[5]}" '
    {
        split($0, fields, "|");
        printf "| %-*s | %-*s | %-*s | %-*s | %-*s | %-*s |\n", max0, fields[1], max1, fields[2], max2, fields[3], max3, fields[4], max4, fields[5], max5, fields[6];
    }'
    
    echo "**************************************************************************************"
}

# Function to display Docker status
display_docker() {
    echo "****************************** DOCKER STATUS ******************************"

    # Print Docker Images
    echo "Docker Images:"
    local images_info
    images_info=$(docker images --format "{{.Repository}}|{{.Tag}}|{{.ID}}|{{.Size}}" 2>/dev/null)
    
    # Determine maximum column widths for images info
    local max_images_lengths=(30 20 15 10)
    calculate_max_widths "$images_info" max_images_lengths

    printf "| %-*s | %-*s | %-*s | %-*s |\n" "${max_images_lengths[0]}" "REPOSITORY" "${max_images_lengths[1]}" "TAG" "${max_images_lengths[2]}" "IMAGE ID" "${max_images_lengths[3]}" "SIZE"
    printf "| %s | %s | %s | %s |\n" "$(str_repeat '-' "${max_images_lengths[0]}")" "$(str_repeat '-' "${max_images_lengths[1]}")" "$(str_repeat '-' "${max_images_lengths[2]}")" "$(str_repeat '-' "${max_images_lengths[3]}")"
    echo "$images_info" | awk -v max0="${max_images_lengths[0]}" -v max1="${max_images_lengths[1]}" -v max2="${max_images_lengths[2]}" -v max3="${max_images_lengths[3]}" '
    {
        split($0, fields, "|");
        printf "| %-*s | %-*s | %-*s | %-*s |\n", max0, fields[1], max1, fields[2], max2, fields[3], max3, fields[4];
    }'

    # Print Docker Containers
    echo ""
    echo "Docker Containers:"
    local containers_info
    containers_info=$(docker ps -a --format "{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}" 2>/dev/null)
    
    # Determine maximum column widths for containers info
    local max_containers_lengths=(30 30 20 20)
    calculate_max_widths "$containers_info" max_containers_lengths

    printf "| %-*s | %-*s | %-*s | %-*s |\n" "${max_containers_lengths[0]}" "NAMES" "${max_containers_lengths[1]}" "IMAGE" "${max_containers_lengths[2]}" "STATUS" "${max_containers_lengths[3]}" "PORTS"
    printf "| %s | %s | %s | %s |\n" "$(str_repeat '-' "${max_containers_lengths[0]}")" "$(str_repeat '-' "${max_containers_lengths[1]}")" "$(str_repeat '-' "${max_containers_lengths[2]}")" "$(str_repeat '-' "${max_containers_lengths[3]}")"
    echo "$containers_info" | awk -v max0="${max_containers_lengths[0]}" -v max1="${max_containers_lengths[1]}" -v max2="${max_containers_lengths[2]}" -v max3="${max_containers_lengths[3]}" '
    {
        split($0, fields, "|");
        printf "| %-*s | %-*s | %-*s | %-*s |\n", max0, fields[1], max1, fields[2], max2, fields[3], max3, fields[4];
    }'
    
    echo "***************************************************************************"
}

# Function to display Nginx domain validation
display_nginx() {
    echo "****************************** NGINX DOMAIN VALIDATION ******************************"
    
    # Extract and format Nginx domain validation information
    local nginx_domains
    nginx_domains=$(grep -r "server_name" /etc/nginx/sites-enabled/ 2>/dev/null | awk -F'[ ;]' '{print $2"|" $1"|" $3}')
    
    # Determine maximum column widths for domains info
    local max_nginx_lengths=(30 30 50)
    calculate_max_widths "$nginx_domains" max_nginx_lengths

    # Print Nginx Domains
    printf "| %-*s | %-*s | %-*s |\n" "${max_nginx_lengths[0]}" "DOMAIN" "${max_nginx_lengths[1]}" "PROXY" "${max_nginx_lengths[2]}" "CONFIGURATION FILE"
    printf "| %s | %s | %s |\n" "$(str_repeat '-' "${max_nginx_lengths[0]}")" "$(str_repeat '-' "${max_nginx_lengths[1]}")" "$(str_repeat '-' "${max_nginx_lengths[2]}")"
    echo "$nginx_domains" | awk -v max0="${max_nginx_lengths[0]}" -v max1="${max_nginx_lengths[1]}" -v max2="${max_nginx_lengths[2]}" '
    {
        split($0, fields, "|");
        printf "| %-*s | %-*s | %-*s |\n", max0, fields[1], max1, fields[2], max2, fields[3];
    }'
    
    echo "**************************************************************************************"
}

# Function to display system logs within a time range
display_time_range() {
    local start_time="$1"
    # local end_time="$2"
    local end_time="${2:-$(date '+%Y-%m-%d %H:%M:%S')}" # Default to current time if end_time is not provided

    echo "****************************** SYSTEM LOGS ******************************"
    
    local log_records
    if [ -z "$end_time" ]; then
        log_records=$(grep -E "$start_time" /var/log/syslog 2>/dev/null)
    else
        log_records=$(awk -v start="$start_time" -v end="$end_time" '$0 >= start && $0 <= end' /var/log/syslog 2>/dev/null)
    fi
    
    if [ -z "$log_records" ]; then
        echo "-- No entries --"
    else
        echo "$log_records"
    fi
    
    echo "**************************************************************************************"
}

# Function to display users and their last login times
display_users() {
    echo "****************************** USERS AND LAST LOGIN TIMES ******************************"
    
    # Extract and format user info
    local user_info
    user_info=$(getent passwd | awk -F':' '{print $1"|" $3"|" $4"|" $5}')
    
    # Determine maximum column widths for user info
    local max_user_lengths=(20 10 10 50)
    calculate_max_widths "$user_info" max_user_lengths

    # Print User Details
    printf "| %-*s | %-*s | %-*s | %-*s |\n" "${max_user_lengths[0]}" "USERNAME" "${max_user_lengths[1]}" "UID" "${max_user_lengths[2]}" "GID" "${max_user_lengths[3]}" "COMMENT"
    printf "| %s | %s | %s | %s |\n" "$(str_repeat '-' "${max_user_lengths[0]}")" "$(str_repeat '-' "${max_user_lengths[1]}")" "$(str_repeat '-' "${max_user_lengths[2]}")" "$(str_repeat '-' "${max_user_lengths[3]}")"
    echo "$user_info" | awk -v max0="${max_user_lengths[0]}" -v max1="${max_user_lengths[1]}" -v max2="${max_user_lengths[2]}" -v max3="${max_user_lengths[3]}" '
    {
        split($0, fields, "|");
        printf "| %-*s | %-*s | %-*s | %-*s |\n", max0, fields[1], max1, fields[2], max2, fields[3], max3, fields[4];
    }'
    
    echo "**************************************************************************************"
}

# Function to monitor all sections periodically
monitor_mode() {
    log_message "Monitoring mode started"
    while true; do
        clear
        log_message "Logging active ports and services:"
        display_ports | tee -a "$LOG_FILE"
        
        log_message "Logging Docker images and containers:"
        display_docker | tee -a "$LOG_FILE"
        
        log_message "Logging Nginx domains and ports:"
        display_nginx | tee -a "$LOG_FILE"
        
        log_message "Logging user logins:"
        display_users | tee -a "$LOG_FILE"
        
        log_message "Finished logging, sleeping for 5 minutes."
        sleep 300 # Sleep for 5 minutes before next check
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
        echo "Usage: $0 [OPTIONS]"
        echo "Options:"
        echo "  -p, --port <port>        Display details for a specific port"
        echo "  -d, --docker [container_name]    List Docker images and containers, or details for a specific container"
        echo "  -n, --nginx [domain]     Display Nginx configuration, or for a specific domain"
        echo "  -u, --users [username]   List users and last login times, or details for a specific user"
        echo "  -t, --time <start> <end> Display logs within a specific time range"
        echo "  -m, --monitor            Monitor mode to display all sections periodically"
        echo "  -h, --help               Display this help message"
        ;;
    *)
        echo "Invalid option. Use -h or --help for usage information."
        ;;
esac




# #!/bin/bash

# # Helper Functions
# calculate_max_widths() {
#     local data="$1"
#     local -n max_lengths=$2
#     local line
#     while IFS= read -r line; do
#         local fields=($line)
#         for i in "${!fields[@]}"; do
#             local length=${#fields[i]}
#             if (( length > max_lengths[i] )); then
#                 max_lengths[i]=$length
#             fi
#         done
#     done <<< "$data"
# }

# str_repeat() {
#     local char=$1
#     local num=$2
#     printf "%${num}s" | tr ' ' "$char"
# }

# log_message() {
#     local message="$1"
#     echo "[INFO] $(date): $message"
# }

# display_ports() {
#     echo "****************************** ACTIVE PORTS AND SERVICES ******************************"
#     local ports_services
#     ports_services=$(sudo ss -tunlp | awk 'NR>1 {print $1"|" $2"|" $3"|" $4"|" $5"|" $6"|" $7"|" $8}')
#     local max_lengths=(8 10 8 8 22 22 20 10)
#     calculate_max_widths "$ports_services" max_lengths

#     local header
#     header="| Netid    | State       | Recv-Q   | Send-Q   | Local Address:Port           | Peer Address:Port            | Process              | Service     |"
#     local separator
#     separator=$(printf "%s" "${max_lengths[@]}" | sed 's/[0-9]\+/\x0/;s/\x0/\x0-/' | tr -d '\x0')
#     echo "$header"
#     echo "$separator"
    
#     if [ -n "$1" ]; then
#         log_message "Displaying details for port $1"
#         sudo ss -tunlp | grep ":$1 " | awk -v max0="${max_lengths[0]}" -v max1="${max_lengths[1]}" -v max2="${max_lengths[2]}" -v max3="${max_lengths[3]}" -v max4="${max_lengths[4]}" -v max5="${max_lengths[5]}" -v max6="${max_lengths[6]}" -v max7="${max_lengths[7]}" '
#             { printf "| %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s |\n", max0, $1, max1, $2, max2, $3, max3, $4, max4, $5, max5, $6, max6, $7, max7, $8; }'
#     else
#         log_message "Listing all active ports and services:"
#         sudo ss -tunlp | awk -v max0="${max_lengths[0]}" -v max1="${max_lengths[1]}" -v max2="${max_lengths[2]}" -v max3="${max_lengths[3]}" -v max4="${max_lengths[4]}" -v max5="${max_lengths[5]}" -v max6="${max_lengths[6]}" -v max7="${max_lengths[7]}" '
#             NR > 1 { printf "| %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s |\n", max0, $1, max1, $2, max2, $3, max3, $4, max4, $5, max5, $6, max6, $7, max7, $8; }'
#     fi
#     echo "**************************************************************************************"
# }

# display_docker() {
#     local container_name="$1"

#     if [ -z "$container_name" ]; then
#         echo "****************************** DOCKER STATUS ******************************"
#         local docker_images
#         docker_images=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" | tail -n +2)
#         local docker_containers
#         docker_containers=$(docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | tail -n +2)
        
#         local max_image_lengths=(20 20 50 20)
#         calculate_max_widths "$docker_images" max_image_lengths
#         local max_container_lengths=(20 20 20 20)
#         calculate_max_widths "$docker_containers" max_container_lengths
        
#         echo "Docker Images:"
#         printf "| %-*s | %-*s | %-*s | %-*s |\n" "${max_image_lengths[0]}" "REPOSITORY" "${max_image_lengths[1]}" "TAG" "${max_image_lengths[2]}" "IMAGE ID" "${max_image_lengths[3]}" "SIZE"
#         printf "| %s | %s | %s | %s |\n" "$(str_repeat '-' "${max_image_lengths[0]}")" "$(str_repeat '-' "${max_image_lengths[1]}")" "$(str_repeat '-' "${max_image_lengths[2]}")" "$(str_repeat '-' "${max_image_lengths[3]}")"
#         echo "$docker_images" | awk -v max0="${max_image_lengths[0]}" -v max1="${max_image_lengths[1]}" -v max2="${max_image_lengths[2]}" -v max3="${max_image_lengths[3]}" '
#         {
#             printf "| %-*s | %-*s | %-*s | %-*s |\n", max0, $1, max1, $2, max2, $3, max3, $4;
#         }'
#         echo ""
#         echo "Docker Containers:"
#         printf "| %-*s | %-*s | %-*s | %-*s |\n" "${max_container_lengths[0]}" "NAMES" "${max_container_lengths[1]}" "IMAGE" "${max_container_lengths[2]}" "STATUS" "${max_container_lengths[3]}" "PORTS"
#         printf "| %s | %s | %s | %s |\n" "$(str_repeat '-' "${max_container_lengths[0]}")" "$(str_repeat '-' "${max_container_lengths[1]}")" "$(str_repeat '-' "${max_container_lengths[2]}")" "$(str_repeat '-' "${max_container_lengths[3]}")"
#         echo "$docker_containers" | awk -v max0="${max_container_lengths[0]}" -v max1="${max_container_lengths[1]}" -v max2="${max_container_lengths[2]}" -v max3="${max_container_lengths[3]}" '
#         {
#             printf "| %-*s | %-*s | %-*s | %-*s |\n", max0, $1, max1, $2, max2, $3, max3, $4;
#         }'
#         echo "***************************************************************************"
#     else
#         echo "****************************** DOCKER CONTAINER DETAILS ******************************"
#         docker inspect "$container_name" --format "Name: {{.Name}}\nImage: {{.Image}}\nStatus: {{.State.Status}}\nPorts: {{.NetworkSettings.Ports}}\n" | grep -v '^$'
#         echo "**************************************************************************************"
#     fi
# }

# display_nginx() {
#     echo "****************************** NGINX DOMAIN VALIDATION ******************************"
#     local nginx_config
#     nginx_config=$(sudo nginx -T 2>/dev/null)
#     local max_lengths=(20 10 50)
#     calculate_max_widths "$nginx_config" max_lengths
    
#     if [ -n "$1" ]; then
#         log_message "Displaying Nginx configuration for domain $1"
#         local domain_config
#         domain_config=$(echo "$nginx_config" | awk "/server_name $1/,/}/")
#         if [ -z "$domain_config" ]; then
#             echo "Domain $1 not found in Nginx configuration."
#         else
#             echo "$domain_config"
#         fi
#     else
#         log_message "Listing all Nginx domains and their ports:"
#         printf "| %-*s | %-*s | %-*s |\n" "${max_lengths[0]}" "DOMAIN" "${max_lengths[1]}" "PROXY" "${max_lengths[2]}" "CONFIGURATION FILE"
#         printf "| %s | %s | %s |\n" "$(str_repeat '-' "${max_lengths[0]}")" "$(str_repeat '-' "${max_lengths[1]}")" "$(str_repeat '-' "${max_lengths[2]}")"
#         echo "$nginx_config" | awk -v max0="${max_lengths[0]}" -v max1="${max_lengths[1]}" -v max2="${max_lengths[2]}" '
#         /server_name/ {
#             server_name = $2;
#             getline;
#             while ($0 !~ /}/) {
#                 if ($0 ~ /listen/) {
#                     port = $2;
#                     gsub(";", "", port);
#                     proxy = $(NF-1);
#                     getline;
#                     printf "| %-*s | %-*s | %-*s |\n", max0, server_name, max1, proxy, max2, "/etc/nginx/nginx.conf";
#                 }
#                 getline;
#             }
#         }'
#     fi
#     echo "**************************************************************************************"
# }

# display_time_range() {
#     local start_time="$1"
#     local end_time="$2"
    
#     # If end_time is not provided, use the current time
#     if [ -z "$end_time" ]; then
#         end_time=$(date '+%Y-%m-%d %H:%M:%S')
#     fi
    
#     echo "****************************** SYSTEM LOGS ******************************"
    
#     # Extract logs within the specified time range
#     local log_records
#     log_records=$(grep -E "$start_time|$end_time" /var/log/syslog 2>/dev/null)
    
#     if [ -z "$log_records" ]; then
#         echo "-- No entries --"
#     else
#         echo "$log_records"
#     fi
    
#     echo "**************************************************************************************"
# }


# display_users() {
#     local username="$1"
#     echo "****************************** USER DETAILS ******************************"
#     local user_info
#     local login_info
    
#     if [ -z "$username" ]; then
#         user_info=$(getent passwd | awk -F: '{print $1"|" $5"|" $6"|" $7}')
#         login_info=$(last -w | awk '{print $1"|" $4" "$5" "$6" "$7" "$8" "$9" "$10}')
#     else
#         user_info=$(getent passwd | grep "^$username:" | awk -F: '{print $1"|" $5"|" $6"|" $7}')
#         login_info=$(last -w "$username" | awk '{print $1"|" $4" "$5" "$6" "$7" "$8" "$9" "$10}')
#     fi

#     local max_user_lengths=(15 20 20 20)
#     calculate_max_widths "$user_info" max_user_lengths
#     local max_login_lengths=(15 20 20 20)
#     calculate_max_widths "$login_info" max_login_lengths

#     printf "| %-*s | %-*s | %-*s | %-*s |\n" "${max_user_lengths[0]}" "Username" "${max_user_lengths[1]}" "Full Name" "${max_user_lengths[2]}" "Home Directory" "${max_user_lengths[3]}" "Shell"
#     printf "| %s | %s | %s | %s |\n" "$(str_repeat '-' "${max_user_lengths[0]}")" "$(str_repeat '-' "${max_user_lengths[1]}")" "$(str_repeat '-' "${max_user_lengths[2]}")" "$(str_repeat '-' "${max_user_lengths[3]}")"
#     echo "$user_info" | awk -v max0="${max_user_lengths[0]}" -v max1="${max_user_lengths[1]}" -v max2="${max_user_lengths[2]}" -v max3="${max_user_lengths[3]}" '
#     {
#         split($0, fields, "|");
#         printf "| %-*s | %-*s | %-*s | %-*s |\n", max0, fields[1], max1, fields[2], max2, fields[3], max3, fields[4];
#     }'
#     echo ""

#     printf "| %-*s | %-*s | %-*s | %-*s |\n" "${max_login_lengths[0]}" "User" "${max_login_lengths[1]}" "Login Time" "${max_login_lengths[2]}" "Logout Time" "${max_login_lengths[3]}" "Duration"
#     printf "| %s | %s | %s | %s |\n" "$(str_repeat '-' "${max_login_lengths[0]}")" "$(str_repeat '-' "${max_login_lengths[1]}")" "$(str_repeat '-' "${max_login_lengths[2]}")" "$(str_repeat '-' "${max_login_lengths[3]}")"
#     echo "$login_info" | awk -v max0="${max_login_lengths[0]}" -v max1="${max_login_lengths[1]}" -v max2="${max_login_lengths[2]}" -v max3="${max_login_lengths[3]}" '
#     {
#         split($0, fields, "|");
#         printf "| %-*s | %-*s | %-*s | %-*s |\n", max0, fields[1], max1, fields[2], max2, fields[3], max3, fields[4];
#     }'
#     echo "***************************************************************************"
# }

# monitor_mode() {
#     while true; do
#         clear
#         display_ports
#         display_docker
#         display_nginx
#         display_time_range "$(date -d '1 hour ago' '+%Y-%m-%d %H:%M:%S')" "$(date '+%Y-%m-%d %H:%M:%S')"
#         display_users
#         sleep 60
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
#         echo "Usage: $0 [OPTIONS]"
#         echo "Options:"
#         echo "  -p, --port <port>        Display details for a specific port"
#         echo "  -d, --docker [container_name]    List Docker images and containers, or details for a specific container"
#         echo "  -n, --nginx [domain]     Display Nginx configuration, or for a specific domain"
#         echo "  -u, --users [username]   List users and last login times, or details for a specific user"
#         echo "  -t, --time <start> <end> Display logs within a specific time range"
#         echo "  -m, --monitor            Monitor mode to display all sections periodically"
#         echo "  -h, --help               Display this help message"
#         ;;
#     *)
#         echo "Invalid option. Use -h or --help for usage information."
#         ;;
# esac





# #!/bin/bash

# # Helper Functions
# calculate_max_widths() {
#     local data="$1"
#     local -n max_lengths=$2
#     while IFS= read -r line; do
#         local fields=($line)
#         for i in "${!fields[@]}"; do
#             local length=${#fields[i]}
#             if (( length > max_lengths[i] )); then
#                 max_lengths[i]=$length
#             fi
#         done
#     done <<< "$data"
# }

# str_repeat() {
#     local char=$1
#     local num=$2
#     printf "%${num}s" | tr ' ' "$char"
# }

# log_message() {
#     local message="$1"
#     echo "[INFO] $(date): $message"
# }

# display_ports() {
#     echo "****************************** ACTIVE PORTS AND SERVICES ******************************"
#     ports_services=$(sudo ss -tunlp | awk 'NR>1 {print $1"|" $2"|" $3"|" $4"|" $5"|" $6"|" $7"|" $8}')
#     max_lengths=(8 10 8 8 22 22 20 10)
#     calculate_max_widths "$ports_services" max_lengths
#     header="| Netid    | State       | Recv-Q   | Send-Q   | Local Address:Port           | Peer Address:Port            | Process              | Service     |"
#     separator=$(printf "%s" "${max_lengths[@]}" | sed 's/[0-9]\+/\x0/;s/\x0/\x0-/' | tr -d '\x0')
#     echo "$header"
#     echo "$separator"
    
#     if [ -n "$1" ]; then
#         log_message "Displaying details for port $1"
#         sudo ss -tunlp | grep ":$1 " | awk -v max0="${max_lengths[0]}" -v max1="${max_lengths[1]}" -v max2="${max_lengths[2]}" -v max3="${max_lengths[3]}" -v max4="${max_lengths[4]}" -v max5="${max_lengths[5]}" -v max6="${max_lengths[6]}" -v max7="${max_lengths[7]}" '
#             { printf "| %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s |\n", max0, $1, max1, $2, max2, $3, max3, $4, max4, $5, max5, $6, max6, $7, max7, $8; }'
#     else
#         log_message "Listing all active ports and services:"
#         sudo ss -tunlp | awk -v max0="${max_lengths[0]}" -v max1="${max_lengths[1]}" -v max2="${max_lengths[2]}" -v max3="${max_lengths[3]}" -v max4="${max_lengths[4]}" -v max5="${max_lengths[5]}" -v max6="${max_lengths[6]}" -v max7="${max_lengths[7]}" '
#             NR > 1 { printf "| %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s |\n", max0, $1, max1, $2, max2, $3, max3, $4, max4, $5, max5, $6, max6, $7, max7, $8; }'
#     fi
#     echo "**************************************************************************************"
# }

# display_docker() {
#     local container_name="$1"

#     if [ -z "$container_name" ]; then
#         echo "****************************** DOCKER STATUS ******************************"
#         docker_images=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" | tail -n +2)
#         docker_containers=$(docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | tail -n +2)
#         max_image_lengths=(20 20 50 20)
#         calculate_max_widths "$docker_images" max_image_lengths
#         max_container_lengths=(20 20 20 20)
#         calculate_max_widths "$docker_containers" max_container_lengths
#         echo "Docker Images:"
#         printf "| %-*s | %-*s | %-*s | %-*s |\n" "${max_image_lengths[0]}" "REPOSITORY" "${max_image_lengths[1]}" "TAG" "${max_image_lengths[2]}" "IMAGE ID" "${max_image_lengths[3]}" "SIZE"
#         printf "| %s | %s | %s | %s |\n" "$(str_repeat '-' "${max_image_lengths[0]}")" "$(str_repeat '-' "${max_image_lengths[1]}")" "$(str_repeat '-' "${max_image_lengths[2]}")" "$(str_repeat '-' "${max_image_lengths[3]}")"
#         echo "$docker_images" | awk -v max0="${max_image_lengths[0]}" -v max1="${max_image_lengths[1]}" -v max2="${max_image_lengths[2]}" -v max3="${max_image_lengths[3]}" '
#         {
#             printf "| %-*s | %-*s | %-*s | %-*s |\n", max0, $1, max1, $2, max2, $3, max3, $4;
#         }'
#         echo ""
#         echo "Docker Containers:"
#         printf "| %-*s | %-*s | %-*s | %-*s |\n" "${max_container_lengths[0]}" "NAMES" "${max_container_lengths[1]}" "IMAGE" "${max_container_lengths[2]}" "STATUS" "${max_container_lengths[3]}" "PORTS"
#         printf "| %s | %s | %s | %s |\n" "$(str_repeat '-' "${max_container_lengths[0]}")" "$(str_repeat '-' "${max_container_lengths[1]}")" "$(str_repeat '-' "${max_container_lengths[2]}")" "$(str_repeat '-' "${max_container_lengths[3]}")"
#         echo "$docker_containers" | awk -v max0="${max_container_lengths[0]}" -v max1="${max_container_lengths[1]}" -v max2="${max_container_lengths[2]}" -v max3="${max_container_lengths[3]}" '
#         {
#             printf "| %-*s | %-*s | %-*s | %-*s |\n", max0, $1, max1, $2, max2, $3, max3, $4;
#         }'
#         echo "***************************************************************************"
#     else
#         echo "****************************** DOCKER CONTAINER DETAILS ******************************"
#         docker inspect "$container_name" --format "Name: {{.Name}}\nImage: {{.Image}}\nStatus: {{.State.Status}}\nPorts: {{.NetworkSettings.Ports}}\n" | grep -v '^$'
#         echo "**************************************************************************************"
#     fi
# }

# display_nginx() {
#     echo "****************************** NGINX DOMAIN VALIDATION ******************************"
#     nginx_config=$(sudo nginx -T 2>/dev/null | awk '{print $0"|" $0}' | sed 's/|/ /')
#     max_lengths=(20 10 50)
#     calculate_max_widths "$nginx_config" max_lengths
#     if [ -n "$1" ]; then
#         log_message "Displaying Nginx configuration for domain $1"
#         domain_config=$(echo "$nginx_config" | awk "/server_name $1/,/}/")
#         if [ -z "$domain_config" ]; then
#             echo "Domain $1 not found in Nginx configuration."
#         else
#             echo "$domain_config"
#         fi
#     else
#         log_message "Listing all Nginx domains and their ports:"
#         printf "| %-*s | %-*s | %-*s |\n" "${max_lengths[0]}" "DOMAIN" "${max_lengths[1]}" "PROXY" "${max_lengths[2]}" "CONFIGURATION FILE"
#         printf "| %s | %s | %s |\n" "$(str_repeat '-' "${max_lengths[0]}")" "$(str_repeat '-' "${max_lengths[1]}")" "$(str_repeat '-' "${max_lengths[2]}")"
#         echo "$nginx_config" | awk -v max0="${max_lengths[0]}" -v max1="${max_lengths[1]}" -v max2="${max_lengths[2]}" '
#         /server_name/ {
#             server_name = $2;
#             getline;
#             while ($0 !~ /}/) {
#                 if ($0 ~ /listen/) {
#                     port = $2;
#                     gsub(";", "", port);
#                     proxy = $(NF-1);
#                     getline;
#                     printf "| %-*s | %-*s | %-*s |\n", max0, server_name, max1, proxy, max2, "/etc/nginx/nginx.conf";
#                 }
#                 getline;
#             }
#         }'
#     fi
#     echo "**************************************************************************************"
# }

# display_time_range() {
#     echo "****************************** SYSTEM LOGS ******************************"
#     start_time="$1"
#     end_time="$2"
#     if [ -z "$start_time" ] || [ -z "$end_time" ]; then
#         echo "Start time and end time must be provided."
#         return
#     fi
#     log_records=$(journalctl --since="$start_time" --until="$end_time" 2>/dev/null)
#     if [ -z "$log_records" ]; then
#         echo "No logs found in the specified time range."
#     else
#         echo "$log_records"
#     fi
#     echo "**************************************************************************************"
# }

# display_users() {
#     local username="$1"
#     echo "****************************** USER DETAILS ******************************"

#     # Capture user details
#     if [ -z "$username" ]; then
#         user_info=$(getent passwd | awk -F: '{print $1"|" $5"|" $6"|" $7}')
#         login_info=$(last -w | awk '{print $1"|" $4" "$5" "$6" "$7" "$8" "$9" "$10}')
#     else
#         user_info=$(getent passwd | grep "^$username:" | awk -F: '{print $1"|" $5"|" $6"|" $7}')
#         login_info=$(last -w "$username" | awk '{print $1"|" $4" "$5" "$6" "$7" "$8" "$9" "$10}')
#     fi

#     # Determine maximum column widths for user details
#     max_user_lengths=(15 20 20 20)
#     calculate_max_widths "$user_info" max_user_lengths

#     # Determine maximum column widths for login records
#     max_login_lengths=(15 20 20 20)
#     calculate_max_widths "$login_info" max_login_lengths

#     # Print User Details
#     printf "| %-*s | %-*s | %-*s | %-*s |\n" "${max_user_lengths[0]}" "Username" "${max_user_lengths[1]}" "Full Name" "${max_user_lengths[2]}" "Home Directory" "${max_user_lengths[3]}" "Shell"
#     printf "| %s | %s | %s | %s |\n" "$(str_repeat '-' "${max_user_lengths[0]}")" "$(str_repeat '-' "${max_user_lengths[1]}")" "$(str_repeat '-' "${max_user_lengths[2]}")" "$(str_repeat '-' "${max_user_lengths[3]}")"
#     echo "$user_info" | awk -v max0="${max_user_lengths[0]}" -v max1="${max_user_lengths[1]}" -v max2="${max_user_lengths[2]}" -v max3="${max_user_lengths[3]}" '
#     {
#         split($0, fields, "|");
#         printf "| %-*s | %-*s | %-*s | %-*s |\n", max0, fields[1], max1, fields[2], max2, fields[3], max3, fields[4];
#     }'
#     echo ""

#     # Print Login Records
#     printf "| %-*s | %-*s | %-*s | %-*s |\n" "${max_login_lengths[0]}" "User" "${max_login_lengths[1]}" "Login Time" "${max_login_lengths[2]}" "Logout Time" "${max_login_lengths[3]}" "Duration"
#     printf "| %s | %s | %s | %s |\n" "$(str_repeat '-' "${max_login_lengths[0]}")" "$(str_repeat '-' "${max_login_lengths[1]}")" "$(str_repeat '-' "${max_login_lengths[2]}")" "$(str_repeat '-' "${max_login_lengths[3]}")"
#     echo "$login_info" | awk -v max0="${max_login_lengths[0]}" -v max1="${max_login_lengths[1]}" -v max2="${max_login_lengths[2]}" -v max3="${max_login_lengths[3]}" '
#     {
#         split($0, fields, "|");
#         printf "| %-*s | %-*s | %-*s | %-*s |\n", max0, fields[1], max1, fields[2], max2, fields[3], max3, fields[4];
#     }'
#     echo "***************************************************************************"
# }

# monitor_mode() {
#     while true; do
#         clear
#         display_ports
#         display_docker
#         display_nginx
#         display_time_range "$(date -d '1 hour ago' '+%Y-%m-%d %H:%M:%S')" "$(date '+%Y-%m-%d %H:%M:%S')"
#         display_users
#         sleep 60
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
#         echo "Usage: $0 [OPTIONS]"
#         echo "Options:"
#         echo "  -p, --port <port>        Display details for a specific port"
#         echo "  -d, --docker [container_name]    List Docker images and containers, or details for a specific container"
#         echo "  -n, --nginx [domain]     Display Nginx configuration, or for a specific domain"
#         echo "  -u, --users [username]   List users and last login times, or details for a specific user"
#         echo "  -t, --time <start> <end> Display logs within a specific time range"
#         echo "  -m, --monitor            Monitor mode to display all sections periodically"
#         echo "  -h, --help               Display this help message"
#         ;;
#     *)
#         echo "Invalid option. Use -h or --help for usage information."
#         ;;
# esac

