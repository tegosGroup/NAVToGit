function Get-UpdateAvailable {    
    Write-Host("$(Get-Date -Format "HH:mm:ss") | Checking for update") -ForegroundColor Cyan
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $obj = Invoke-WebRequest -Uri "https://api.github.com/repos/tegosGroup/NAVToGit/releases/latest" -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
    } catch{
        Write-Host("$(Get-Date -Format "HH:mm:ss") | No connection to Github.") -ForegroundColor Red
        return $false
    }
    $currentRepo = (Get-Item $PSScriptRoot).Parent.FullName

    $currentVersion = Get-Content -Path (Join-Path -Path $currentRepo -ChildPath "version") -First 1
    $remoteVersion = $obj.tag_name
    if (-Not ($currentVersion -eq $remoteVersion)) {
        $changes = $obj.body
        Write-Host("$(Get-Date -Format "HH:mm:ss") | Found new version $remoteVersion :") -ForegroundColor Cyan
        Write-Host("$changes") -ForegroundColor White
    }else {
        Write-Host("$(Get-Date -Format "HH:mm:ss") | You are already up to date") -ForegroundColor Green
    }
    Set-Content -Path (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\.lastupdatecheck") -Value (Get-Date -Format "dd.MM.yyyy HH:mm:ss")
    return -Not ($currentVersion -eq $remoteVersion)
}

function Invoke-UpdateProcess{
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $obj = Invoke-WebRequest -Uri "https://api.github.com/repos/tegosGroup/NAVToGit/releases/latest" -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host("$(Get-Date -Format "HH:mm:ss") | No connection to Github.") -ForegroundColor Red
        break
    }
    $currentRepo = (Get-Item $PSScriptRoot).Parent.FullName
    $tempRepo = Join-Path -Path $env:TEMP -ChildPath "NavToGitUpdate"
    $downloadFile = Join-Path -Path $tempRepo -ChildPath "update.zip"

    Remove-Item -Path $tempRepo -Recurse -Force -ErrorAction SilentlyContinue > $null
    New-Item -path $tempRepo -ItemType Directory > $null

    Write-Host("$(Get-Date -Format "HH:mm:ss") | Downloading latest release...") -ForegroundColor Cyan
    Invoke-WebRequest -Uri $obj.zipball_url -OutFile $downloadFile

    Write-Host("$(Get-Date -Format "HH:mm:ss") | Extracting download zip") -ForegroundColor Cyan
    Expand-Archive -Path $downloadFile -DestinationPath $tempRepo -Force

    Remove-Item -Path $downloadFile -Force

    Write-Host("$(Get-Date -Format "HH:mm:ss") | Updating your local version") -ForegroundColor Cyan
    Robocopy (Get-ChildItem $tempRepo)[0].FullName $currentRepo /mov /mir /xd .git > $null

    Remove-Item -Path $tempRepo -Recurse -Force > $null
    Write-Host("$(Get-Date -Format "HH:mm:ss") | Update finished") -ForegroundColor Green
    
    Set-Content -Path (Join-Path -Path $currentRepo -ChildPath "VERSION") -Value $obj.tag_name
}

function Get-UpdateCheckNeeded {
    $CheckNeeded = $true
    if (Test-Path (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\.lastupdatecheck")) {
        [datetime]$lastUpdateCheck = [datetime]::parseexact((Get-Content (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\.lastupdatecheck") -First 1),"dd.MM.yyyy HH:mm:ss",$null)
        if (((Get-Date) - $lastUpdateCheck).TotalDays -lt 1) {
            $CheckNeeded = $false
        }
    }
    return $CheckNeeded
}
