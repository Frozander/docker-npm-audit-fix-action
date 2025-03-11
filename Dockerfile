FROM node:20-alpine

LABEL maintainer="Frozander"

# Install git and other dependencies
RUN apk add --no-cache git curl jq

# Set up working directory
WORKDIR /action

# Copy scripts and make them executable
COPY entrypoint.sh /action/
COPY scripts/ /action/scripts/
RUN chmod +x /action/entrypoint.sh
RUN chmod +x /action/scripts/*.sh

# Set entrypoint
ENTRYPOINT ["/action/entrypoint.sh"] 