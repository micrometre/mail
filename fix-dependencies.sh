#!/bin/bash

# Quick fix for Python cryptography dependencies and SQLite3
echo "🔧 Installing Python cryptography dependencies and SQLite3..."

sudo apt update
sudo apt install -y \
    python3-cryptography \
    python3-cffi \
    python3-dev \
    libffi-dev \
    libssl-dev \
    build-essential \
    sqlite3

echo "✅ Dependencies installed!"
echo "You can now run the deployment again."