# Use an official Ubuntu as a parent image
FROM ubuntu:latest

# Set the maintainer label
LABEL maintainer="devmichaelalao@gmail.com"

# Copy the scripts into the container
COPY devopsfetch.sh /usr/local/bin/devopsfetch.sh
COPY setup.sh /usr/local/bin/setup.sh

# Make the scripts executable
RUN chmod +x /usr/local/bin/devopsfetch.sh /usr/local/bin/setup.sh

# Run the setup script
RUN /usr/local/bin/setup.sh

# Set the entrypoint to the devopsfetch script
ENTRYPOINT ["/usr/local/bin/devopsfetch.sh"]

# Default command to run when container starts
CMD ["-h"]
