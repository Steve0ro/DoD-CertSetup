$CertDownloadURL = "http://militarycac.com/maccerts/AllCerts.zip"
$DownloadDir = "$env:USERPROFILE\Downloads\CACSetup"
$CertFileName = "AllCerts"
$CertZipFile = "$DownloadDir\AllCerts.zip"
$CertExtractDir = "$DownloadDir\Certs"
$ExitSuccess = 0
$ErrorNoCertStore = 88
$CertStoreName = "Root"

function Print-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Yellow
}

function Print-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Check-Admin {
    if (-not ([bool](New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
        Print-Error "This script must be run as Administrator."
        exit 1
    }
}

function Download-Certs {
    Print-Info "Downloading DoD certificates..."
    if (-not (Test-Path $DownloadDir)) {
        New-Item -ItemType Directory -Path $DownloadDir | Out-Null
    }
    Invoke-WebRequest -Uri $CertDownloadURL -OutFile $CertZipFile
    Print-Info "Extracting certificates..."
    Expand-Archive -Path $CertZipFile -DestinationPath $CertExtractDir -Force
}

function Import-Certs {
    Print-Info "Importing certificates into the Windows Certificate Store..."
    $CertFiles = Get-ChildItem -Path $CertExtractDir -Filter *.cer
    foreach ($CertFile in $CertFiles) {
        Print-Info "Importing $($CertFile.Name)..."
        Import-Certificate -FilePath $CertFile.FullName -CertStoreLocation "Cert:\LocalMachine\$CertStoreName" | Out-Null
    }
    Print-Info "Certificates imported successfully."
}

function Check-And-Install-Chrome {
    Print-Info "Checking for Google Chrome installation..."
    $ChromePath = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
    if (-not (Test-Path $ChromePath)) {
        Print-Info "Google Chrome is not installed."
        $Choice = Read-Host "Would you like to install Google Chrome? (Y/N)"
        if ($Choice -eq "Y" -or $Choice -eq "y") {
            Print-Info "Installing Google Chrome..."
            $LocalTempDir = $env:TEMP
            $ChromeInstaller = "ChromeInstaller.exe"
            (New-Object System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller")
            & "$LocalTempDir\$ChromeInstaller" /silent /install
            $Process2Monitor = "ChromeInstaller"
            Do {
                $ProcessesFound = Get-Process | Where-Object { $Process2Monitor -contains $_.Name } | Select-Object -ExpandProperty Name
                If ($ProcessesFound) {
                    "Still running: $($ProcessesFound -join ', ')" | Write-Host
                    Start-Sleep -Seconds 2
                } else {
                    Remove-Item "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose
                }
            } Until (!$ProcessesFound)
            Print-Info "Google Chrome installed successfully."
        } else {
            Print-Error "Google Chrome is required for this setup. Exiting..."
            exit 1
        }
    } else {
        Print-Info "Google Chrome is already installed."
    }
}

function Cleanup {
    Print-Info "Cleaning up temporary files..."
    if (Test-Path $DownloadDir) {
        Remove-Item -Recurse -Force -Path $DownloadDir
    }
    Print-Info "Temporary files cleaned up."
}

function Manage-ExecutionPolicy {
    $OriginalPolicy = Get-ExecutionPolicy -Scope Process

    if ($OriginalPolicy -notin @("Unrestricted", "Bypass")) {
        Print-Info "Current Execution Policy: $OriginalPolicy. Changing to Unrestricted..."
        
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force
    }

    try {
        Main-Script
    } finally {
        Print-Info "Restoring Execution Policy to $OriginalPolicy..."
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy $OriginalPolicy -Force
    }
}

function Main-Script {
    Check-Admin
    Check-And-Install-Chrome
    Download-Certs
    Import-Certs
    Cleanup
    Print-Info "CAC setup complete. A system reboot may be required."
}

Manage-ExecutionPolicy
