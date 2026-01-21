#!/bin/bash

# =============================================================================
# Create Keystore Script
# =============================================================================
# This script creates an encrypted keystore file for deploying contracts.
# The keystore is encrypted with a password and stored securely.
# =============================================================================

set -e

# Configuration
KEYSTORE_DIR="./keystore"
KEYSTORE_PATH="${KEYSTORE_DIR}/deployer"
PASSWORD_PATH="${KEYSTORE_DIR}/deployer.password.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=============================================="
echo "  Create Encrypted Keystore for Deployment"
echo "=============================================="
echo ""

# Check if keystore already exists
if [ -f "$KEYSTORE_PATH" ]; then
    echo -e "${YELLOW}Warning: Keystore file already exists at ${KEYSTORE_PATH}${NC}"
    read -p "Do you want to overwrite it? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Aborted."
        exit 0
    fi
fi

# Create keystore directory if it doesn't exist
mkdir -p "$KEYSTORE_DIR"

# Prompt for private key
echo -e "${YELLOW}Enter your private key (without 0x prefix):${NC}"
read -s PRIVATE_KEY
echo ""

# Validate private key format (64 hex characters)
if ! [[ "$PRIVATE_KEY" =~ ^[a-fA-F0-9]{64}$ ]]; then
    echo -e "${RED}Error: Invalid private key format. Must be 64 hex characters without 0x prefix.${NC}"
    exit 1
fi

# Prompt for password
echo -e "${YELLOW}Enter encryption password:${NC}"
read -s PASSWORD
echo ""

echo -e "${YELLOW}Confirm encryption password:${NC}"
read -s PASSWORD_CONFIRM
echo ""

# Check password match
if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
    echo -e "${RED}Error: Passwords do not match.${NC}"
    exit 1
fi

# Check password length
if [ ${#PASSWORD} -lt 8 ]; then
    echo -e "${RED}Error: Password must be at least 8 characters.${NC}"
    exit 1
fi

# Save password to file
echo -n "$PASSWORD" > "$PASSWORD_PATH"
chmod 600 "$PASSWORD_PATH"

# Create keystore using cast wallet import
echo ""
echo "Creating encrypted keystore..."

# Use cast to create keystore
cast wallet import deployer --private-key "$PRIVATE_KEY" --keystore-dir "$KEYSTORE_DIR" --unsafe-password "$PASSWORD" 2>/dev/null

# Rename the keystore file to match expected path
if [ -f "${KEYSTORE_DIR}/deployer" ]; then
    echo -e "${GREEN}Keystore created successfully!${NC}"
else
    # cast wallet import creates file with account name
    CREATED_FILE=$(ls -t "$KEYSTORE_DIR" | head -1)
    if [ -n "$CREATED_FILE" ] && [ "$CREATED_FILE" != "deployer.password.txt" ]; then
        mv "${KEYSTORE_DIR}/${CREATED_FILE}" "$KEYSTORE_PATH"
        echo -e "${GREEN}Keystore created successfully!${NC}"
    else
        echo -e "${RED}Error: Failed to create keystore.${NC}"
        exit 1
    fi
fi

# Set secure permissions
chmod 600 "$KEYSTORE_PATH"

# Verify the keystore
echo ""
echo "Verifying keystore..."
ADDR=$(cast wallet address --keystore "$KEYSTORE_PATH" --password "$PASSWORD" 2>/dev/null)

if [ -n "$ADDR" ]; then
    echo -e "${GREEN}Keystore verification successful!${NC}"
    echo ""
    echo "=============================================="
    echo -e "  ${GREEN}Keystore Setup Complete${NC}"
    echo "=============================================="
    echo ""
    echo "Files created:"
    echo "  - Keystore: $KEYSTORE_PATH"
    echo "  - Password: $PASSWORD_PATH"
    echo ""
    echo "Deployer address: $ADDR"
    echo ""
    echo -e "${YELLOW}IMPORTANT: These files are in .gitignore and will NOT be committed.${NC}"
    echo -e "${YELLOW}Make sure to backup these files securely!${NC}"
else
    echo -e "${RED}Error: Keystore verification failed.${NC}"
    exit 1
fi
