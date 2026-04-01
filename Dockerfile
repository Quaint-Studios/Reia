# =========================================================================
# REIA DEDICATED SERVER DOCKERFILE
# =========================================================================
# Hi there! I hope you're having a great day.
#
# INSTRUCTIONS:
# 1. To build the image using the 'latest' version and default hash:
#    docker build -t reia-server:latest .
#
# 2. To build a specific version:
#    docker build --build-arg VERSION=v1.1.0 -t reia-server:v1.1.0 .
#
# 3. To run the server in the background:
#    docker run -d --name reia-instance-1 -p 7777:7777/udp reia-server:latest
# =========================================================================

# Downloads, Verifies, and Extracts
FROM ubuntu:24.04 AS builder

# Install wget (downloading), unzip (extracting), jq (JSON parsing), and coreutils (checksums)
RUN apt-get update && apt-get install -y wget unzip jq ca-certificates coreutils && rm -rf /var/lib/apt/lists/*

# or, as an example, VERSION=v1.1.0
ARG VERSION=latest
ARG R2_BASE_URL=https://game.r2.playreia.com/releases/${VERSION}

WORKDIR /setup

# 1. Download manifest.json
# 2. Parse the filename and hash using jq
# 3. Download the actual zip file
# 4. Verify the checksum against the downloaded file
# 5. Extract and make the executable runnable
RUN wget -qO manifest.json ${R2_BASE_URL}/manifest.json && \
	ZIP_FILE=$(jq -r '.binaries["Linux Server"].file' manifest.json) && \
	EXPECTED_HASH=$(jq -r '.binaries["Linux Server"].sha256' manifest.json) && \
	echo "Found $ZIP_FILE with hash $EXPECTED_HASH in manifest." && \
	wget -qO "$ZIP_FILE" "${R2_BASE_URL}/$ZIP_FILE" && \
	echo "$EXPECTED_HASH  $ZIP_FILE" | sha256sum -c - && \
	unzip "$ZIP_FILE" -d /reia-server && \
	chmod +x /reia-server/reia-linux-server

# - # - # - # - # - # - # - # - # - # - # - # - # - # - #

# Runtime Secure & Bloat-Free
FROM ubuntu:24.04

# SECURITY: Create a non-root user so the server cannot compromise the host machine if exploited
RUN useradd -m -s /bin/bash reiauser

WORKDIR /app

# Copy ONLY the extracted game files from the builder stage
# The wget, unzip, and zip files from Stage 1 are completely discarded
COPY --from=builder --chown=reiauser:reiauser /reia-server /app/

# Switch to the restricted user
USER reiauser

# Expose the port you use for your server
EXPOSE 7777/udp

# Run the Reia headless server
CMD ["sh", "-c", "exec ./reia-linux-server --server --headless"]
