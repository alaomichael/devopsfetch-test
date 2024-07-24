```markdown

# DevOpsFetch

DevOpsFetch is a tool for retrieving and monitoring server information, designed to be easy to deploy and use with Docker.

## Features

- Display all active ports and services.
- Provide detailed information about a specific port.
- List all Docker images and containers.
- Provide detailed information about a specific container.
- Display all Nginx domains and their ports.
- Provide detailed configuration information for a specific domain.
- List all users and their last login times.
- Provide detailed information about a specific user.
- Display activities within a specified time range.
- Continuous monitoring and logging of server activities.

#### Installation and Configuration Steps

1. **Download the scripts**:

   ```sh
   wget https://github.com/alaomichael/devopsfetch/blob/main/devopsfetch.sh
   wget https://github.com/alaomichael/devopsfetch/blob/main/setup.sh
   ```

2. **Make the scripts executable**:

   ```sh
   chmod +x devopsfetch.sh
   chmod +x setup.sh
   ```

3. **Run the installation script**:

   ```sh
   sudo ./setup.sh
   ```

#### Usage Examples

- **Display all active ports and services**:

  ```sh
  sudo devopsfetch.sh -p
  ```

- **Display detailed information about a specific port**:

  ```sh
  sudo devopsfetch.sh -p <port_number>
  ```

- **List all Docker images and containers**:

  ```sh
  sudo devopsfetch.sh -d
  ```

- **Display detailed information about a specific Docker container**:

  ```sh
  sudo devopsfetch.sh -d <container_name>
  ```

- **Display all Nginx domains and their ports**:

  ```sh
  sudo devopsfetch.sh -n
  ```

- **Display detailed configuration information for a specific domain**:

  ```sh
  sudo devopsfetch.sh -n <domain>
  ```

- **List all users and their last login times**:

  ```sh
  sudo devopsfetch.sh -u
  ```

- **Provide detailed information about a specific user**:

  ```sh
  sudo devopsfetch.sh -u <username>
  ```

- **Display activities within a specified time range**:

    ```sh
    sudo devopsfetch.sh -t <start_time> <end_time>
    ```

- **Start continuous monitoring and logging**:

  ```sh
  sudo devopsfetch.sh -m

  ```

#### Logging Mechanism

Logs are stored in `/var/log/devopsfetch/devopsfetch.log`. Logs are rotated and managed by the script itself. To retrieve logs:

```sh
sudo cat /var/log/devopsfetch/devopsfetch.log
```
