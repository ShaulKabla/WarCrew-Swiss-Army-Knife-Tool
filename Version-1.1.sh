#!/bin/bash

# WarCrew Scanning Tool
# This script is designed to assist with CTFs and ethical hacking.
# It creates a new directory for each run and performs Nmap and Nikto scans.
# Version 1.1 - Define functions, GoBuster logfile bug, Adding User Choice, First version of Network-Investigation.

# Function For Welcome Screen

display_welcome_banner() {
    echo "Welcome to WarCrew Scanning Tool"
    echo "The tool uses different methods to help you find the right way"
    echo "Be safe and don't cause any harm with this tool"

    cat << "EOF"
//////////////////////////////////////////////////////////
    __          __         _____                   
    \ \        / /        / ____|                  
     \ \  /\  / /_ _ _ __| |     _ __ _____      __
      \ \/  \/ / _` | '__| |    | '__/ _ \ \ /\ / /
       \  /\  / (_| | |  | |____| | |  __/\ V  V / 
        \/  \/ \__,_|_|   \_____|_|  \___| \_/\_/ 
        
/////////////////////////////////////////////////////////
EOF
}

# Function to handle errors
handle_error() {
    local error_message="$1"
    echo "Something went wrong: $error_message"
    exit 1  # Use non-zero exit status to indicate failure
}

# Check root function
check_root() {
    if [ "$EUID" -ne 0 ]; then
        handle_error "This script may require root privileges for some scans. Please run it as root or with sudo."
    fi
}

# Function for CTF directory block
creating_directory() {
    read -p "Enter CTF name: " ctf
    desktop_dir="/home/$SUDO_USER/Desktop/"
    ctf_dir="$desktop_dir/$ctf"

    if [ -d "$ctf_dir" ]; then
        handle_error "CTF directory '$ctf' already exists on the desktop."
    fi

    mkdir -p "$ctf_dir" || handle_error "Failed to create CTF directory."
    log_dir="$ctf_dir/logs"
    mkdir -p "$log_dir" || handle_error "Failed to create CTF directory."
}

# Function to generate timestamp
generate_timestamp() {
    ts=$(date "+%d-%m-%Y")
}

# Function to get target information from the user
get_target() {
    read -p "Enter IP target or hostname: " target

    # Handling Error if target is blank. -z to check if $target holds anything.
    if [ -z "$target" ]; then
        handle_error "Target IP or hostname cannot be empty."
    fi
}

# This Funcation running Nmap
nmap_scan() {
    nmap_log="$log_dir/nmap_scan_$(date '+%Y%m%d_%H%M%S').txt"
    
    echo "Select Nmap scan type:"
    options=("Quiet Scan" "Aggressive Scan" "Vulnerability Scan" "Network Discovery" "Custom Scan")
    select opt in "${options[@]}"; do
        case $opt in
            "Quiet Scan")
                nmap_command="nmap -sS -T1 -A -vv $target"
                break
                ;;
            "Aggressive Scan")
                nmap_command="nmap -sCVT -Pn -T4 -p- -vv -A $target"
                break
                ;;
            "Vulnerability Scan")
                nmap_command="nmap --script=vuln -Pn -T4 -vv $target"
                break
                ;;
            "Network Discovery")
                # Network Discovery Scan for identifying live hosts and services
                nmap_command="nmap -sn -PE -PA21,23,80,3389 $target"
                break
                ;;
            "Custom Scan")
                read -p "Enter your custom Nmap command (excluding target): " custom_cmd
                nmap_command="nmap $custom_cmd $target"
                break
                ;;
            *)
                echo "Invalid option. Please try again."
                ;;
        esac
    done

    echo "Starting Nmap scan. Please wait..."
    echo -e "Using the following command: \n$nmap_command"

    # Run Nmap command directly to the shell and log the output with errors.
    eval "$nmap_command" > "$nmap_log" 2>&1
    
    echo "---------------------------------"
    echo "Nmap scan completed. Results are saved in '$nmap_log'."
}

# This Function running Nikto
nikto_scan() {
    echo "Running Nikto scan..."
    read -p "Do you want to perform an SSL scan? (Y/N): " ssl_scan
    read -p "Do you want to perform an authenticated scan? (Y/N): " auth_scan

    # Creating a var for auth_scan
    auth_credentials=""

    # Nikto log file
    nikto_log="$log_dir/nikto_scan_$ts.txt"

    nikto_command="nikto -h $target -output $nikto_log -ask no"

    # Cheking if the user looking diffrent kind of options nikto has to offer and use them
    if [ "$ssl_scan" == "Y" ]; then
        nikto_command="$nikto_command -ssl"
    fi

    if [ "$auth_scan" == "Y" ]; then
        read -p "Enter authentication (username:password): " auth_credentials
        nikto_command="$nikto_command -id $auth_credentials"
    fi

    echo -e "Running Nikto with the following command: \n$nikto_command"

    eval "$nikto_command" > "$nikto_log" 2>&1
    
    echo "---------------------------------"
    echo "Nikto scan completed. Results are saved in '$nikto_log'."
}

# This function running GoBuster
gobuster_scan() {
    echo "Select GoBuster scan type:"
    echo "1. Quieter Scan"
    echo "2. Aggressive Scan"
    read -p "Enter your choice (1/2): " gobuster_scan_type

    # GoBuster log file
    gobuster_log="$log_dir/gobuster_scan_$ts.txt"

    # Cheking what wordlist the user want to use, and if he looking for quite or aggresive scan
    # if [ -z ] is to check if the wordlist_path is empty by length
    # The default path is for Kali-Linux only.

    if [ "$gobuster_scan_type" == "1" ]; then
        read -p "Enter the path to the wordlist (Or empty for default): " wordlist_path
        if [ -z "$wordlist_path" ]; then
            gobuster_wordlist="/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt" # Default Path
        else
            gobuster_wordlist="$wordlist_path"
        fi
        gobuster_command="gobuster dir -u $target -w $gobuster_wordlist -o $gobuster_log -t 5 -q -n"
    elif [ "$gobuster_scan_type" == "2" ]; then
        read -p "Enter the path to the wordlist (Or empty for default): " wordlist_path
        if [ -z "$wordlist_path" ]; then
            gobuster_wordlist="/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt" # Default Path
        else
            gobuster_wordlist="$wordlist_path"
        fi
        gobuster_command="gobuster dir -u $target -w $gobuster_wordlist -o $gobuster_log -t 50 -x .html,.css,.js,.php,.py,.log,.cgi,.txt,.sh -r 0 -q"
    fi

    echo -e "Starting GoBuster scan. Using the following command: \n$gobuster_command"

    eval "$gobuster_command" > "$gobuster_log" 2>&1
    
    echo "---------------------------------"
    echo "GoBuster scan completed. Results are saved in '$gobuster_log'."
}

network_investigation() {
	network_inv_logfile="$log_dir/network_investigation_$ts.txt"
	
	echo "Performing Ping, Traceroute, Whois lookup, Dig to give you some info about $target"
	ping -c 4 $target >> "$network_inv_logfile" 2>&1
	traceroute $target >> "$network_inv_logfile" 2>&1
	whois $target >> "$network_inv_logfile" 2>&1
	dig $target >> "$network_inv_logfile" 2>&1
	echo "---------------------------------"
	echo "Thank you, All the data had been save into your log direcotry."
}

goodbye() {
	echo "Thank you for using WarCrew Scanning Tool. You have all the logs in your CTF directory"

	cat << "EOF"
//////////////////////////////////////////////////
____               ____             
| __ ) _   _  ___  | __ ) _   _  ___ 
|  _ \| | | |/ _ \ |  _ \| | | |/ _ \
| |_) | |_| |  __/ | |_) | |_| |  __/
|____/ \__, |\___| |____/ \__, |\___|
       |___/              |___/      
EOF

	read -n 1 -s -r -p "Press any key to exit..."
	exit 0
}

# Main script execution
# Adding while loop and let the user choose his scans

display_welcome_banner
check_root
creating_directory
generate_timestamp
get_target


while true; do
    echo "---------------------------------"
    echo "Choose a function to run:"
    echo "1. Nmap Scan"
    echo "2. Nikto Scan"
    echo "3. GoBuster Scan"
    echo "4. Network Investigation"
    echo "5. Exit"
    
    read -p "Enter your choice (1-5): " user_choice

    case $user_choice in
        1) nmap_scan ;;
        2) nikto_scan ;;
        3) gobuster_scan ;;
        4) network_investigation ;;
        5) goodbye ;;
        *) echo "Invalid choice. Please enter a number between 1 and 5." ;;
    esac
done
