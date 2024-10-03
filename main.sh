#!/bin/bash

# Install figlet if not already installed
if ! command -v figlet &> /dev/null; then
    echo "Figlet not found, installing..."
    sudo apt-get update && sudo apt-get install -y figlet
fi

# Function to print the introduction
print_intro() {
  echo -e "\033[94m"
  figlet -f /usr/share/figlet/starwars.flf "POP-MINING B0T" 
  echo -e "\033[0m"

  echo -e "\033[92m📡 Farming POP-MINING\033[0m"   # Green color for the description 
  echo -e "\033[96m👨‍💻 Created by: Cipher\033[0m"  # Cyan color for the creator
  echo -e "\033[95m🔍 Initializing HEMI-POP B0T...\033[0m"  # Magenta color for the initializing message 
  echo "════════════════════════════════════════════════════════════"
  echo "║       Follow us for updates and support:                 ║"
  echo "║                                                          ║"
  echo "║     Twitter:                                             ║"
  echo "║     https://twitter.com/cipher_airdrop                   ║"
  echo "║                                                          ║"
  echo "║     Telegram:                                            ║"
  echo "║     - https://t.me/+tFmYJSANTD81MzE1                     ║"
  echo "╚════════════════════════════════════════════════════════════"

  # Prompt for user confirmation
  read -p "$(echo -e '\033[91mWill you F** HEMI-POP Airdrop? (Y/N): \033[0m')" answer  # Red color for the prompt 
  if [[ "$answer" != "Y" && "$answer" != "y" ]]; then
    echo -e "\033[91mAborting installation.\033[0m"  # Red color for abort message
    exit 1
  fi
}

# Call the intro function before proceeding
print_intro

show() {
    echo -e "\033[1;35m$1\033[0m"
}

# Function to check the latest version of HemiNetwork release
check_latest_version() {
    for i in {1..3}; do
        LATEST_VERSION=$(curl -s https://api.github.com/repos/hemilabs/heminetwork/releases/latest | jq -r '.tag_name')
        if [ -n "$LATEST_VERSION" ]; then
            show "Latest version available: $LATEST_VERSION"
            return 0
        fi
        show "Attempt $i: Failed to fetch the latest version. Retrying..."
        sleep 2
    done

    show "Failed to fetch the latest version after 3 attempts. Please check your internet connection or GitHub API limits."
    exit 1
}

# Check if the keygen and popmd binaries are present and download them if not
download_binaries() {
    ARCH=$(uname -m)

    if [ "$ARCH" == "x86_64" ]; then
        if [ ! -f "./keygen" ] || [ ! -f "./popmd" ]; then
            show "Downloading binaries for x86_64 architecture..."
            wget --quiet --show-progress "https://github.com/hemilabs/heminetwork/releases/download/$LATEST_VERSION/heminetwork_${LATEST_VERSION}_linux_amd64.tar.gz" -O "heminetwork_${LATEST_VERSION}_linux_amd64.tar.gz"
            tar -xzf "heminetwork_${LATEST_VERSION}_linux_amd64.tar.gz" -C ./
            mv heminetwork_${LATEST_VERSION}_linux_amd64/keygen ./
            mv heminetwork_${LATEST_VERSION}_linux_amd64/popmd ./
        fi
    elif [ "$ARCH" == "arm64" ]; then
        if [ ! -f "./keygen" ] || [ ! -f "./popmd" ]; then
            show "Downloading binaries for arm64 architecture..."
            wget --quiet --show-progress "https://github.com/hemilabs/heminetwork/releases/download/$LATEST_VERSION/heminetwork_${LATEST_VERSION}_linux_arm64.tar.gz" -O "heminetwork_${LATEST_VERSION}_linux_arm64.tar.gz"
            tar -xzf "heminetwork_${LATEST_VERSION}_linux_arm64.tar.gz" -C ./
            mv heminetwork_${LATEST_VERSION}_linux_arm64/keygen ./
            mv heminetwork_${LATEST_VERSION}_linux_arm64/popmd ./
        fi
    else
        show "Unsupported architecture: $ARCH"
        exit 1
    fi
}

# Step 1: Check and download the latest version
check_latest_version
download_binaries

# Step 2: Ask how many PoP mining instances to create
echo
show "How many PoP mining instances do you want to create?"
read -p "Enter the number of instances: " instance_count

# Step 3: Ask if the user wants to use SOCKS5 proxies
echo
read -p "Do you want to use SOCKS5 proxies for the containers? (y/N): " use_proxy

# Step 4: Create wallet for each instance
> wallet.txt

for i in $(seq 1 $instance_count); do
    echo
    show "Generating wallet $i..."
    
    # Step 5: Run keygen to generate wallet
    ./keygen -secp256k1 -json -net="testnet" > "wallet_$i.json"
    
    if [ $? -ne 0 ]; then
        show "Failed to generate wallet $i. Please check if keygen is working properly."
        exit 1
    fi

    pubkey_hash=$(jq -r '.pubkey_hash' "wallet_$i.json")
    priv_key=$(jq -r '.private_key' "wallet_$i.json")
    ethereum_address=$(jq -r '.ethereum_address' "wallet_$i.json")

    echo "Wallet $i - Ethereum Address: $ethereum_address" >> ~/PoP-Mining-Wallets.txt
    echo "Wallet $i - BTC Address: $pubkey_hash" >> ~/PoP-Mining-Wallets.txt
    echo "Wallet $i - Private Key: $priv_key" >> ~/PoP-Mining-Wallets.txt
    echo "--------------------------------------" >> ~/PoP-Mining-Wallets.txt

    show "Wallet $i details saved in wallet.txt"

    show "Join: https://discord.gg/hemixyz"
    show "Request faucet from faucet channel to this address: $pubkey_hash"
    echo
    read -p "Have you requested faucet for wallet $i? (y/N): " faucet_requested
    if [[ ! "$faucet_requested" =~ ^[Yy]$ ]]; then
        show "Please request faucet before proceeding."
        exit 1
    fi

    # Step 6: Ask for SOCKS5 proxy for each instance if user opted to use proxy
    if [[ "$use_proxy" =~ ^[Yy]$ ]]; then
        echo
        read -p "Enter SOCKS5 proxy for container $i (format: user:pass@IP:port): " socks5_proxy
    fi

    # Step 7: Create Dockerfile for each instance
    mkdir -p "pop_container_$i"
    cp keygen popmd pop_container_$i/  # Copy binaries into container directory
    cat << EOF > "pop_container_$i/Dockerfile"
FROM ubuntu:latest
RUN apt-get update && apt-get install -y wget jq curl
COPY ./keygen /usr/local/bin/keygen
COPY ./popmd /usr/local/bin/popmd
RUN chmod +x /usr/local/bin/keygen /usr/local/bin/popmd
WORKDIR /app
CMD ["popmd"]
EOF

    # Step 8: Build Docker image
    docker build -t pop_container_$i ./pop_container_$i

    # Step 9: Run Docker container with or without SOCKS5 proxy
    if [[ "$use_proxy" =~ ^[Yy]$ ]]; then
        docker run -d --name pop_mining_$i --env POPM_BTC_PRIVKEY="$priv_key" --env POPM_STATIC_FEE=150 --env POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public --env ALL_PROXY="socks5://$socks5_proxy" pop_container_$i
        show "PoP mining container $i started with SOCKS5 proxy: $socks5_proxy."
    else
        docker run -d --name pop_mining_$i --env POPM_BTC_PRIVKEY="$priv_key" --env POPM_STATIC_FEE=150 --env POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public pop_container_$i
        show "PoP mining container $i started without a proxy."
    fi
done

show "PoP mining is successfully started for all wallets and containers."
