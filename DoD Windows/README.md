# Overview
CAC_Setup.ps1 is a PowerShell script designed to set up a Windows environment for Common Access Card (CAC) use, including the optional installation of Google Chrome and the importing of DoD certificates into the Windows Certificate Store.

This script simplifies the process of preparing your system for secure CAC-based authentication by automating the installation of necessary tools, downloading required certificates, and ensuring compatibility with popular web browsers.

## Features
- Checks Administrative Privileges: Ensures the script is run as an administrator for proper installation.
- Optional Chrome Installation: Prompts the user to install Google Chrome if it is not already installed.

### DoD Certificate Management:
- Downloads the latest DoD certificates from the official source.
- Imports certificates into the Windows Certificate Store for use by browsers like Chrome.
- Cleanup: Removes temporary files created during the setup process.


## Requirements
- Operating System: Windows 10 or later
- Administrator Privileges: The script requires administrative access to make system-level changes.
- PowerShell: Version 5.1 or later

## Installation
Download the Script: Clone the repository or download the CAC_Setup.ps1 file:

```bash
Copy code
git clone https://github.com/steve0ro/DoD-Windows-Setup

cd DoD-Windows-Setup
```



### Run the Script: Open PowerShell as Administrator and run:
```powershell
.\setup.ps1

```

### Troubleshoot

- If you recieve a red prompt like the one below, set your execution policy to unrestricted or bypass. Once the script is done set back to restricted.

```
.\setup.ps1 : File C:\Users\dev\Desktop\setup.ps1 cannot be loaded because running scripts is disabled on this system.
For more information, see about_Execution_Policies at https:/go.microsoft.com/fwlink/?LinkID=135170.
At line:1 char:1
+ .\setup.ps1
+ ~~~~~~~~~~~
    + CategoryInfo          : SecurityError: (:) [], PSSecurityException
    + FullyQualifiedErrorId : UnauthorizedAccess
```

```powershell

# Checks what the current policy is
Get-Execution policy

# Set policy to Unrestricted
Set-ExectionPolicy Unrestricted -Force

# Run the script again
.\setup.ps1


# Once the script is complete, run

Set-ExectionPolicy Restricted
```

Follow Prompts:

If Google Chrome is not installed, you’ll be prompted to install it.
The script will download and import DoD certificates into the Windows Certificate Store.
