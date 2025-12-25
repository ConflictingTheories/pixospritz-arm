#!/bin/bash
set -e

TARGET_DIR=$1

# Make init script executable
chmod +x ${TARGET_DIR}/sbin/game_init

# Create game directory
mkdir -p ${TARGET_DIR}/opt/game

echo "Post-build completed"
