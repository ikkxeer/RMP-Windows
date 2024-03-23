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

$MultitoolDecision = Read-Host "Select option"

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
}
}
}

# Function to the main menu
function MainMenu {
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
