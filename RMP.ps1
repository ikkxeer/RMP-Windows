$Version = 1.0

Clear-Host # Limpiar ventana al iniciar

# Elevación a Administrador
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
        $global:Credentials = Get-credentials
        Space
        Write-Host "Credentials have been successfully obtained!" -ForegroundColor Green
    }
    else {
        Write-Host "$Hostname do not have PS Remote enabled correctly or the remote configuration is not correct" -ForegroundColor Red
        Space
        Start-Sleep -Seconds 2
        exit
    }
}

MainMenu
