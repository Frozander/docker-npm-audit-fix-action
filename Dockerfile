FROM node:22-alpine

LABEL maintainer="Frozander"

# Install git, curl, jq, Python and build dependencies for native modules
RUN apk add --no-cache git curl jq python3 py3-setuptools make g++ build-base cairo-dev pango-dev jpeg-dev giflib-dev

# Set up working directory
WORKDIR /action

# Copy scripts and make them executable
COPY entrypoint.sh /action/
COPY scripts/ /action/scripts/
RUN chmod +x /action/entrypoint.sh
RUN chmod +x /action/scripts/*.sh

# Set entrypoint
ENTRYPOINT ["/action/entrypoint.sh"] 