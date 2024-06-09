# WarCrew Swiss Army Knife Tool

WarCrew Swiss Army Knife Tool is a comprehensive Bash script designed to assist with CTFs (Capture The Flag) and ethical hacking endeavors. It provides a variety of features and utilities to streamline the process of scanning, reconnaissance, and exploitation during security assessments. Below is an overview of its key functionalities:

## Features:

### 1. Automated Reverse Shells:
   - Generates staged and stageless reverse shells for quick deployment.
   - Supports PHP and Windows Meterpreter payloads.

### 2. Notes Management:
   - Allows users to create and edit notes specific to each CTF session.
   - Notes are saved in a dedicated file within the CTF directory.

### 3. Network Scans:
   - **Nmap Scan:** Conducts various types of scans including Quick, Aggressive-Long, Quiet, Vuln, and Version scans using Nmap.
   - **Nikto Scan:** Performs web server vulnerability scans with optional SSL and authenticated scan features.
   - **GoBuster Scan:** Executes directory enumeration scans with options for Quick and Aggressive scans using GoBuster.

### 4. Network Investigation:
   - Performs a comprehensive investigation of the target network, including Ping, Traceroute, Whois lookup, and DNS (Dig) queries.
   - Consolidates results into a single log file for easy reference.

### 5. Directory Management:
   - Automatically creates a dedicated directory structure for each CTF session on the user's desktop.
   - Organizes logs and notes within the CTF directory for better organization.

### 6. User-Friendly Interface:
   - Offers an intuitive menu-driven interface for easy navigation and execution of various functions.
   - Provides informative prompts and error handling to guide users through the process.

## How to Use:
   - Simply execute the script in a Bash-compatible environment.
   - Follow the on-screen prompts to select desired actions and provide necessary inputs.
   - Ensure proper permissions (root or sudo) for executing certain scans that require elevated privileges.

## Prerequisites:
   - Bash-compatible environment (Linux or macOS).
   - Necessary dependencies such as Nmap, Nikto, GoBuster, and Netcat.
   - Metasploit Framework (for generating reverse shells).

## Disclaimer:
   - This tool is intended for educational and ethical hacking purposes only.
   - Use responsibly and adhere to applicable laws and regulations.

For detailed usage instructions and examples, please refer to the script's inline documentation.
