function Uninstall-Program($programName) {
    $uninstallPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    foreach ($path in $uninstallPaths) {
        $programs = Get-ItemProperty -Path $path | Where-Object { $_.DisplayName -like "*$programName*" }
        foreach ($program in $programs) {
            if ($program.UninstallString) {
                try {
                    & $program.UninstallString /quiet /norestart | Out-Null
                    Write-Host "Uninstalled: $($program.DisplayName)"
                } catch {
                    Write-Host "Failed to uninstall: $($program.DisplayName)"
                }
            }
        }
    }
}

function Remove-Service($serviceName) {
    $services = Get-Service | Where-Object { $_.DisplayName -like "*$serviceName*" -or $_.ServiceName -like "*$serviceName*" }
    foreach ($service in $services) {
        try {
            Stop-Service -Name $service.ServiceName -Force
            Write-Host "Stopped service: $($service.DisplayName)"
            sc.exe delete $service.ServiceName | Out-Null
            Write-Host "Deleted service: $($service.DisplayName)"
        } catch {
            Write-Host "Failed to remove service: $($service.DisplayName)"
        }
    }
}


function Remove-RegistryEntries($path, $keyword) {
    $keys = Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$keyword*" }
    foreach ($key in $keys) {
        try {
            Remove-Item -Path $key.PSPath -Recurse -Force
            Write-Host "Deleted registry key: $($key.PSPath)"
        } catch {
            Write-Host "Failed to delete registry key: $($key.PSPath)"
        }
    }
}


function Remove-Directories($path, $keyword) {
    $directories = Get-ChildItem -Path $path -Recurse -Directory -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*$keyword*" }
    foreach ($directory in $directories) {
        try {
            Remove-Item -Path $directory.FullName -Recurse -Force
            Write-Host "Deleted directory: $($directory.FullName)"
        } catch {
            Write-Host "Failed to delete directory: $($directory.FullName)"
        }
    }
}

Uninstall-Program "New Relic"


Remove-Service "newrelic"


$registryPaths = @(
    "HKLM:\SOFTWARE\",
    "HKLM:\SYSTEM\CurrentControlSet\Services\",
    "HKCU:\SOFTWARE\"
)

foreach ($path in $registryPaths) {
    Remove-RegistryEntries $path "newrelic"
}


$pathsToSearch = @(
    "C:\Program Files\",
    "C:\Program Files (x86)\",
    "C:\ProgramData\",
    "C:\Users\*\AppData\Local\",
    "C:\Users\*\AppData\Roaming\"
)

foreach ($path in $pathsToSearch) {
    Remove-Directories $path "newrelic"
}


$targetFolder = "C:\Program Files\New Relic"
if (Test-Path -Path $targetFolder) {
    try {
        Remove-Item -Path $targetFolder -Recurse -Force
        Write-Host "Deleted directory: $targetFolder"
    } catch {
        Write-Host "Failed to delete directory: $targetFolder"
    }
}

Write-Host "New Relic cleanup completed."
