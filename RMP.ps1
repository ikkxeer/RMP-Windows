$Version = "1.0"

Clear-Host # Clear window on startup

# Elevation to administrator in case he is not
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))  
{  
  $arguments = "& '" +$myinvocation.mycommand.definition + "'"
  Start-Process powershell.exe -Verb runAs -ArgumentList $arguments
  Break
}

# Function to print space in the terminal
function Space {
    Write-Host " "    
}

# Function to open the dialog box to explorer
function Open-Dialog($initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "JPG Files (*.jpg)|*.jpg|All Files (*.*)|*.*"
    $OpenFileDialog.ShowDialog() | Out-Null
    $global:ImageSelected = $OpenFileDialog.filename
    }

function MultitoolMenu {
    Clear-Host
    Write-Host @"
     __  __       _ _   _ _              _   __  __                  
    |  \/  |_   _| | |_(_) |_ ___   ___ | | |  \/  | ___ _ __  _   _ 
    | |\/| | | | | | __| | __/ _ \ / _ \| | | |\/| |/ _ \ '_ \| | | |
    | |  | | |_| | | |_| | || (_) | (_) | | | |  | |  __/ | | | |_| |
    |_|  |_|\__,_|_|\__|_|\__\___/ \___/|_| |_|  |_|\___|_| |_|\__,_|

"@ -ForegroundColor Yellow
Write-Host "1. Change Wallpaper" -ForegroundColor Yellow
Space
Write-Host "2. Send Notification" -ForegroundColor Yellow
Space
Write-Host "3. Create Local User" -ForegroundColor Yellow
Space
Write-Host "4. Create Local Group" -ForegroundColor Yellow
Space
Write-Host "5. Enable AutoTray in taskbar" -ForegroundColor Yellow
Space
Write-Host "6. Enable/Disable Firewall" -ForegroundColor Yellow
Space
Write-Host "7. Install apps" -ForegroundColor Yellow
Space
$MultitoolDecision = Read-Host "Select option"

# Change Wallpaper
if ($MultitoolDecision -eq "1") {
    Add-Type -AssemblyName System.Windows.Forms
    Space
    Write-Host "Select your jpg image: " -ForegroundColor Yellow
    Open-Dialog
    Space
    Write-Host "You have selected the following image: $global:ImageSelected" -ForegroundColor Yellow
    Space
    Write-Host "Sending image to remote machine..." -ForegroundColor Yellow
    Space
        $Session = New-PSSession -ComputerName $Hostname -Credential $global:Credentials
        $UserMachine = $global:Credentials.UserName
        $Path = "C:\Users\$UserMachine\Documents"
        Copy-Item $global:ImageSelected -Destination $Path -ToSession $Session
        Write-Host "Image sent successfully!" -ForegroundColor Green
        Space
        $Archivo = Split-Path -Path $global:ImageSelected -Leaf 
        $TotalPath =  $Path + '\' + $Archivo
        Write-Host "Changing wallpaper of the connected machine..." -ForegroundColor Yellow
        Invoke-Command -ComputerName $Hostname -Credential $global:Credentials -ScriptBlock {
            Rename-Item -LiteralPath $Using:TotalPath -NewName "Background.jpg"
            $NewPathBackground = "C:\Users\$env:Username\Documents\Background.jpg"
            Function Set-WallPaper {
                param (
                    [parameter(Mandatory=$True)]
                    # Provide path to image
                    [string]$Image,
                    # Provide wallpaper style that you would like applied
                    [parameter(Mandatory=$False)]
                    [ValidateSet('Fill', 'Fit', 'Stretch', 'Tile', 'Center', 'Span')]
                    [string]$Style
                )
                 
                $WallpaperStyle = Switch ($Style) {
                    "Fill" {"10"}
                    "Fit" {"6"}
                    "Stretch" {"2"}
                    "Tile" {"0"}
                    "Center" {"0"}
                    "Span" {"22"}
                }
                 
                If($Style -eq "Tile") {
                 
                    New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force
                    New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -PropertyType String -Value 1 -Force
                 
                }
                Else {
                 
                    New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force
                    New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -PropertyType String -Value 0 -Force
                 
                }
                 
                Add-Type -TypeDefinition @" 
                using System; 
                using System.Runtime.InteropServices;
                  
                public class Params
                { 
                    [DllImport("User32.dll",CharSet=CharSet.Unicode)] 
                    public static extern int SystemParametersInfo (Int32 uAction, 
                                                                   Int32 uParam, 
                                                                   String lpvParam, 
                                                                   Int32 fuWinIni);
                }
"@ 
                  
                    $SPI_SETDESKWALLPAPER = 0x0014
                    $UpdateIniFile = 0x01
                    $SendChangeEvent = 0x02
                  
                    $fWinIni = $UpdateIniFile -bor $SendChangeEvent
                  
                    $ret = [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $Image, $fWinIni)
                }
                 
                Set-WallPaper -Image $NewPathBackground -Style Fill
            # Delete wallpaper cache
            Remove-Item "C:\Users\admin\AppData\Roaming\Microsoft\Windows\Themes\*" -Force -Recurse
            # Restart explorer to refresh wallpaper
            Stop-Process -Name explorer -Force
            Start-Process explorer
            Start-Sleep -Seconds 2
            # Close explorer window
            $a = (New-Object -comObject Shell.Application).Windows() |  ? { $_.FullName -ne $null} |
            ? { $_.FullName.toLower().Endswith('\explorer.exe') } 

            $a | % {  $_.Quit() }
            }
}
# Create a Local User
elseif ($MultitoolDecision -eq "3") {
    Clear-Host
    Write-Host "--- Enter the credentials for the new user below ---" -BackgroundColor Green -ForegroundColor Black
    Space
    $LocalUsername = Read-Host "Name for the new user"
    Space
    $Password = Read-Host "Password for the new user" -AsSecureString
    Space
    $Description = Read-Host "Decsription for the new user"
    Space
    Invoke-Command -ComputerName $Hostname -Credential $global:Credentials -ScriptBlock {
        try {
            New-LocalUser -Name $Using:LocalUsername -Password $Using:Password -FullName $Using:LocalUsername -Description $Using:Description
            Add-LocalGroupMember -Group Usuarios -Member $Using:LocalUsername
            Write-Host "User $Using:LocalUsername has been created successfully!" -ForegroundColor Green
            Space
            Pause
        }
        catch {
            Write-Host "An error occurred trying to create the user $Using:LocalUsername..." -ForegroundColor Red
            Space
            Pause
        }
    }
}
# Create local Group
elseif ($MultitoolDecision -eq "4") {
    Clear-Host
    Write-Host "--- Enter the credentials for the new group below ---" -BackgroundColor Green -ForegroundColor Black
    Space
    $LocalGroupName = Read-Host "Name for the new group"
    Space
    $Description = Read-Host "Decsription for the new group"
    Space
    Invoke-Command -ComputerName $Hostname -Credential $global:Credentials -ScriptBlock {
        try {
            New-LocalGroup -Name $Using:LocalGroupName
            Write-Host "Group $Using:LocalGroupName has been created successfully!" -ForegroundColor Green
            Space
            Pause
        }
        catch {
            Write-Host "An error occurred trying to create the group $Using:LocalGroupName..." -ForegroundColor Red
            Space
            Pause
        }
    }
}
# Enable AutoTray in taskbar
elseif ($MultitoolDecision -eq "5") {
    Clear-Host
    Write-Host "Enabling all icons on the taskbar..." -ForegroundColor Yellow
    Space
    Invoke-Command -ComputerName $Hostname -Credential $global:Credentials -ScriptBlock {
        try {
            Set-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer EnableAutoTray 0
            ps explorer | kill
            Write-Host "All icons will be displayed on the taskbar now!" -ForegroundColor Green
            Write-Host " "
            Pause
        }
        catch {
            Write-Host "An error occurred trying to enable all icons on the taskbar..." -ForegroundColor Red
            Write-Host " "
            Pause
        }
    }
}
# Enable OR Disable Firewall
elseif ($MultitoolDecision -eq "6") {
    Clear-Host
    Write-Host "1. Enable" -ForegroundColor Yellow
    Space
    Write-Host "2. Disable" -ForegroundColor Yellow
    Space
    $FirewallDecision = Read-Host "Write your decision"
    if ($FirewallDecision -eq "1") {
        Invoke-Command -ComputerName $Hostname -Credential $global:Credentials -ScriptBlock {
            Write-Host "Trying to enable all Firewalls..." -ForegroundColor Yellow
            try {
                Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
                Write-Host "All firewalls have been enabled correctly!" -ForegroundColor Green
            }
            catch {
                Write-Host "An error occurred trying to enable firewalls" -ForegroundColor Red
            }    
        }
    }
    elseif ($FirewallDecision -eq "2") {
        Invoke-Command -ComputerName $Hostname -Credential $global:Credentials -ScriptBlock {
            Write-Host "Trying to disable all Firewalls..." -ForegroundColor Yellow
            try {
                Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
                Write-Host "All firewalls have been disable correctly!" -ForegroundColor Green
            }
            catch {
                Write-Host "An error occurred trying to disable firewalls" -ForegroundColor Red
            }    }
        else {
            Write-Host "Invalid selection..." -ForegroundColor Red
            Space
            Pause
        }    
        }    
}
# Install apps
elseif ($MultitoolDecision -eq "7") {
    Clear-Host
    Write-Host "Checking that winget is installed on the remote pc..." -ForegroundColor Yellow
    Space
    Invoke-Command -ComputerName $Hostname -Credential $global:Credentials -ScriptBlock {
        $VerifyInstall = winget
        if ($VerifyInstall) {
            Write-Host "Winget is installed in the remote machine!" -ForegroundColor Green
            Write-Host " "
        }
        else {
            Write-Host "Winget is not installed in the remote machine..." -ForegroundColor Red
            Write-Host " "
            $progressPreference = 'silentlyContinue'
            Write-Host "Downloading and installing winget..." -ForegroundColor Yellow
            Write-Host " "
            if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                # Download the latest version of winget
                Invoke-WebRequest -Uri "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -OutFile "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle" -UseBasicParsing

                # Install winget
                Add-AppxPackage -Path "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
            } else {
                Write-Output "Winget is already installed..." -ForegroundColor Yellow
            }
            Write-Host "Winget has been installed correctlly!" -ForegroundColor Green
        }
    }
    $AppToInstall = Read-Host "Write the name of the app you want to install"
    Invoke-Command -ComputerName $Hostname -Credential $global:Credentials -ScriptBlock {
        winget install $Using:AppToInstall --source winget --force --silent --accept-package-agreements --accept-source-agreements
    }
    Pause
}
}

# Function to the main menu
function MainMenu {
    Clear-Host
    Write-Host @"
  _______    ____    ____   _______   
 |_   __ \  |_   \  /   _| |_   __ \  
  | |__) |    |   \/   |    | |__) | 
  |  __ /     | |\  /| |    |  ___/  
 _| |  \ \_  _| |_\/_| |_  _| |_     
|____| |___||_____||_____||_____|       
"@ -ForegroundColor Yellow
Space
$global:Hostname = Read-Host "Hostname or Ip to the host: "
Space
$TestPSRemote = Test-WSMan $Hostname -ErrorAction SilentlyContinue
    if ($TestPSRemote) {
        Write-Host "The connection with $Hostname was successfully!" -ForegroundColor Green
        Space
        Write-Host "Getting credentials to the connection with the machine: $Hostname" -ForegroundColor Yellow
        Space
        $global:Credentials = Get-Credential
        Space
        Write-Host "Credentials have been successfully obtained!" -ForegroundColor Green
        Space
        Write-Host "Testing credentials to $Hostname..." -ForegroundColor Yellow
        Space
        $TestingCredentials = Invoke-Command -ComputerName $Hostname -Credential $global:Credentials -ScriptBlock {pwd}
        if ($TestingCredentials) {
            Write-Host "Credentials have been successfully verified!" -ForegroundColor Green
            Space
            Write-Host "Opening multitool menu..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            MultitoolMenu
        }
        else {
            Write-Host "Failed to verify credentials for $Hostname" -ForegroundColor Red
            Space
            Start-Sleep -Seconds 2
            exit
        }
    }
    else {
        Write-Host "$Hostname do not have PS Remote enabled correctly or the remote configuration is not correct" -ForegroundColor Red
        Space
        Start-Sleep -Seconds 2
        exit
    }
}

do {
    MainMenu
} while ($true)
