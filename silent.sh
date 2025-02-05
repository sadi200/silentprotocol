#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

curl -s https://raw.githubusercontent.com/sadi200/Multiple/refs/heads/main/Logo.sh | bash
echo "Starting Auto Silent Protocol"
sleep 5

log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local border="-----------------------------------------------------"
    
    echo -e "${border}"
    case $level in
        "INFO")
            echo -e "${CYAN}[INFO] ${timestamp} - ${message}${NC}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS] ${timestamp} - ${message}${NC}"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR] ${timestamp} - ${message}${NC}"
            ;;
        *)
            echo -e "${YELLOW}[UNKNOWN] ${timestamp} - ${message}${NC}"
            ;;
    esac
    echo -e "${border}\n"
}

common() {
    local duration=$1
    local message=$2
    local end=$((SECONDS + duration))
    local spinner="⣷⣯⣟⡿⣿⡿⣟⣯⣷"
    
    echo -n -e "${YELLOW}${message}...${NC} "
    while [ $SECONDS -lt $end ]; do
        printf "\b${spinner:((SECONDS % ${#spinner}))%${#spinner}:1}"
        sleep 0.1
    done
    printf "\r${GREEN}Done!${NC} \n"
}

log "INFO" "1. Update system"
sudo apt update && sudo apt upgrade -y

log "INFO" "2. Memeriksa dan menginstal Python 3 serta pip"
if ! command -v python3 &>/dev/null; then
    log "INFO" "Python 3 tidak ditemukan, menginstal..."
    sudo apt install -y python3 python3-pip
else
    log "SUCCESS" "Python 3 sudah terinstal."
fi

log "INFO" "3. Memeriksa dan menginstal pip jika belum ada"
if ! python3 -m pip &>/dev/null; then
    log "INFO" "pip tidak ditemukan, menginstal pip..."
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    python3 get-pip.py
else
    log "SUCCESS" "pip sudah terinstal."
fi

log "INFO" "4. Memeriksa dan menginstal dependensi"
python3 -m pip install --upgrade pip
python3 -m pip install requests --quiet

log "INFO" "5. Membuat folder Silent-Protocol"
mkdir -p ~/Silent-Protocol && cd ~/Silent-Protocol

log "INFO" "6. Membuat file tokens.txt"
touch tokens.txt

log "INFO" "7. Membuat skrip Python automation.py"
cat > automation.py <<EOF
import requests
import time
import threading

position_url = "https://ceremony-backend.silentprotocol.org/ceremony/position"
ping_url = "https://ceremony-backend.silentprotocol.org/ceremony/ping"
token_file = "tokens.txt"

def load_tokens():
    try:
        with open(token_file, "r") as file:
            tokens = [line.strip() for line in file if line.strip()]
            print(f"{len(tokens)} tokens loaded.")
            return tokens
    except Exception as e:
        print(f"Error loading tokens: {e}")
        return []

def get_headers(token):
    return {
        "Authorization": f"Bearer {token}",
        "Accept": "*/*",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
    }

def get_position(token):
    try:
        response = requests.get(position_url, headers=get_headers(token))
        if response.status_code == 200:
            data = response.json()
            print(f"[Token {token[:6]}...] Position: Behind {data['behind']}, Time Remaining: {data['timeRemaining']}")
            return data
        print(f"[Token {token[:6]}...] Failed to fetch position. Status: {response.status_code}")
    except Exception as e:
        print(f"[Token {token[:6]}...] Error fetching position: {e}")

def ping_server(token):
    try:
        response = requests.get(ping_url, headers=get_headers(token))
        if response.status_code == 200:
            data = response.json()
            print(f"[Token {token[:6]}...] Ping Status: {data}")
            return data
        print(f"[Token {token[:6]}...] Failed to ping. Status: {response.status_code}")
    except Exception as e:
        print(f"[Token {token[:6]}...] Error pinging: {e}")

def run_automation(token):
    while True:
        get_position(token)
        ping_server(token)
        time.sleep(10)

def main():
    tokens = load_tokens()
    if not tokens:
        print("No tokens available. Exiting.")
        return
    
    threads = []
    for token in tokens:
        thread = threading.Thread(target=run_automation, args=(token,))
        thread.start()
        threads.append(thread)
    
    for thread in threads:
        thread.join()

if __name__ == "__main__":
    main()
EOF

log "INFO" "8. Mengatur izin eksekusi pada automation.py"
chmod +x automation.py

log "INFO" "9. Menjalankan automation.py dalam screen"
log "INFO" "10. Buat Screen : screen -R Silent-Protocol "
log "INFO" "11. tambahkan tokens : cd ~/Silent-Protocol && nano tokens.txt"
log "INFO" "12. Run  : python3 automation.py"
log "SUCCESS" "Instalasi selesai! Masukkan token di tokens.txt lalu jalankan: screen -r Silent-Protocol"
