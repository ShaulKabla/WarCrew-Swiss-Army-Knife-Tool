#!/bin/bash

# WarCrew Scanning Tool
# This script is designed to assist with CTFs and ethical hacking.
# It creates a new directory for each run and performs Nmap and Nikto scans.

echo "Welcome to WarCrew Scaning Tool"
echo "The tool using diffrent methods such as Nmap, Nikto, GoBuster and so much more fun"
echo "Be safe and dont make any harm with the tool"

cat << "EOF"


//////////////////////////////////////////////////
__          __         _____                   
\ \        / /        / ____|                  
 \ \  /\  / /_ _ _ __| |     _ __ _____      __
  \ \/  \/ / _` | '__| |    | '__/ _ \ \ /\ / /
   \  /\  / (_| | |  | |____| | |  __/\ V  V / 
    \/  \/ \__,_|_|   \_____|_|  \___| \_/\_/ 
    
//////////////////////////////////////////////////    
    
EOF
    
# Adding a block to check if the user run as root

if [ "$EUID" -ne 0 ]; then
    echo "This script may require root privileges for some scans. Please run it as root or with sudo."
    exit 1
fi


read -p "Enter CTF name: " ctf

desktop_dir="/home/$SUDO_USER/Desktop/" # $HOME var leads to root direcotry insted of the user desktop. $SUDO_USER VAR stores the username that run sudo command
ctf_dir="$desktop_dir/$ctf"

if [ -d "$ctf_dir" ]; then
	echo "CTF directory '$ctf' already exists on the desktop."
	exit 1
fi

mkdir -p "$ctf_dir"

log_dir="$ctf_dir/logs"
mkdir -p "$log_dir"

#Creating a timestamp for each log - %[X] repsents Year,month,day
ts=$(date "+%d-%m-%Y")

# Nmap log file
nmap_log="$log_dir/nmap_scan_$ts.txt"


read -p "Enter IP target or hostname: " target

# Handling Error if target is blank. -z to check if $target holding anything.
if [ -z "$target" ]; then
    echo "Target IP or hostname cannot be empty."
    exit 1
fi

# I modify the script for 2 options of scaning with Nmap using the eval method fro nikto section
# -sC - For scripts, -sV - for version, -Pn - disable host discovery, -A - Aggresive scan, -p- - for all ports.
# 2>&1 using to redirect both stdout and stderr to the same file

# Nmap block
echo "Select Nmap scan type:"
echo "1. Quiet Scan"
echo "2. Aggressive Scan"
read -p "Enter your choice (1/2): " nmap_scan_type

echo "Starting Nmap scan. Please wait..."

# If statment block for Nmap scans
if [ "$nmap_scan_type" == "1" ]; then
    nmap_command="nmap -sS -T1 -A -vv $target"
elif [ "$nmap_scan_type" == "2" ]; then
    nmap_command="nmap -sCVT -Pn -T5 -p- -vv -A $target"
else
    echo "Invalid choice. Defaulting to Aggressive Scan."
    nmap_command="nmap -sCVT -Pn -T5 -p- -vv -A $target"
fi

echo "Starting Nmap scan. Using the following command:"
echo "$nmap_command"

# Run Nmap scan and log the output
eval "$nmap_command" > "$nmap_log" 2>&1

echo "Nmap scan completed. Results are saved in '$nmap_log'."

# Nikto block
echo "Runing Nikto scan..."
read -p "Do you want to perform an SSL scan? (Y/N): " ssl_scan
read -p "Do you want to perform an authenticated scan? (Y/N): " auth_scan

#Creating a var for auth_scan
auth_credentials=""

# Nikto log file
nikto_log="$log_dir/nikto_scan_$ts.txt"

nikto_command="nikto -h $target -output $nikto_log -ask no"

# If statment block
if [ "$ssl_scan" == "Y" ]; then
	nikto_command="$nikto_command -ssl"
fi

if [ "$auth_scan" == "Y" ]; then
	read -p "Enter authentication (username:password): " auth_credentials
	nikto_command="$nikto_command -id $auth_credentials"
fi

echo "Running Nikto with the following command:"
echo "$nikto_command"

eval "$nikto_command" > "$nikto_log" 2>&1

echo "Nikto scan completed. Results are saved in '$nikto_log'."

# GoBuster block
echo "Select GoBuster scan type:"
echo "1. Quieter Scan"
echo "2. Aggressive Scan"
read -p "Enter your choice (1/2): " gobuster_scan_type

# GoBuster log file
gobuster_log="$log_dir/gobuster_scan_$ts.txt"

# If block for GuBuster scans
# if [ -z ] is to check if the wordlist_path is empty by length
# The default path is for Kali-Linux distro only.
# Flags for GoBuster - -t (sets of threads), -r(delay in Ms), -q & -n (for quite scan and foucs lisiting directories and files), -a(aggresive scan)

if [ "$gobuster_scan_type" == "1" ]; then
    read -p "Enter the path to the wordlist (Or emppty for default): " wordlist_path
    if [ -z "$wordlist_path" ]; then
        gobuster_wordlist="/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt" #Default Path
    else
        gobuster_wordlist="$wordlist_path"
    fi
    gobuster_command="gobuster dir -u $target -w $gobuster_wordlist -o $gobuster_log -t 5 -q -n"
elif [ "$gobuster_scan_type" == "2" ]; then
    read -p "Enter the path to the wordlist (Or emppty for default): " wordlist_path
    if [ -z "$wordlist_path" ]; then
        gobuster_wordlist="/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt" #Default Path
    else
        gobuster_wordlist="$wordlist_path"
    fi
    gobuster_command="gobuster dir -u $target -w $gobuster_wordlist -o $gobuster_log -t 50 -x .html,.css,.js,.php,.py,.log,.cgi,.txt,.sh -r 0"
fi

echo "Starting GoBuster scan. Using the following command:"
echo "$gobuster_command"

eval "$gobuster_command" > "$gobuster_log" 2>&1

echo "GoBuster scan completed. Results are saved in '$gobuster_log'."

cat << "EOF"


EOF
echo "Thank you for using WarCrew Scanning Tool. You have all the logs in you Ctf directory"

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
