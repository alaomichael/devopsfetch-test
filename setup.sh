#!/bin/bash

LOG_FILE="/var/log/devopsfetch.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Install necessary dependencies
log_message "Updating package lists"
sudo apt-get update

log_message "Installing required packages"
sudo apt-get install -y docker.io nginx iproute2 net-tools

# Move devopsfetch.sh to /usr/local/bin
if sudo mv devopsfetch.sh /usr/local/bin/devopsfetch.sh; then
    sudo chmod +x /usr/local/bin/devopsfetch.sh
    log_message "Moved devopsfetch.sh to /usr/local/bin and made it executable"
else
    log_message "Failed to move devopsfetch.sh"
    echo "Error: Could not move devopsfetch.sh to /usr/local/bin"
    exit 1
fi

# Check if systemd is available
if pidof systemd > /dev/null; then
    # Create devopsfetch service file
    SERVICE_FILE="/etc/systemd/system/devopsfetch.service"

    sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=Devopsfetch Monitoring Service
After=network.target

[Service]
ExecStart=/usr/local/bin/devopsfetch.sh -m
Restart=always

[Install]
WantedBy=multi-user.target
EOL

    # Enable and start the service
    log_message "Enabling and starting the devopsfetch service"
    sudo systemctl daemon-reload
    sudo systemctl enable devopsfetch.service
    sudo systemctl start devopsfetch.service

    log_message "Devopsfetch installed and service started with systemd."
    echo "Devopsfetch installed and service started with systemd."
else
    log_message "System does not use systemd."
    echo "System does not use systemd. Please start devopsfetch manually using the following command:"
    echo "sudo /usr/local/bin/devopsfetch.sh -m"
fi
