# .SYNOPSIS
# Build a flutter windows app located in /src and optionally package it as msix.
# Packaging the app requires the msix package being added to the flutter project.

param (
    # Build the example app of a package.
    [switch]$example = $false,
    # Package the app as msix.
    [switch]$msix = $false
)

# Copy file from C:\src to current directory. C:\src will be a directory from the host
# and the container user lacks the required permissions for that directory.
# The content of the ephemeral directory of the windows folder may not be copied.
# It contains links, that may not be valid within the container.
# The data for other platforms than windows are not copied at all, as they will not be used anyway.
[System.Collections.ArrayList]$platforms = @("android", "ios", "macos", "linux", "windows", "web")
if ($example) {
    # If the src contains a package, the ephemeral directory is located at C:\src\example\windows\flutter\ephemeral .
    Copy-Item -Path (Get-Item -Path "C:\src\*" -Exclude ('example')).FullName -Destination . -Recurse
    New-Item -Path .\example -ItemType Directory
    Copy-Item -Path (Get-Item -Path "C:\src\example\*" -Exclude $platforms).FullName -Destination .\example\ -Recurse
    New-Item -Path .\example\windows -ItemType Directory
    Copy-Item -Path (Get-Item -Path "C:\src\example\windows\*" -Exclude ('flutter')).FullName -Destination .\example\windows\ -Recurse
    New-Item -Path .\example\windows\flutter -ItemType Directory
    Copy-Item -Path (Get-Item -Path "C:\src\example\windows\flutter\*").FullName -Destination .\example\windows\flutter\
} else {
    # If the src contains an app, the ephemeral directory is located at C:\src\windows\flutter\ephemeral .
    Copy-Item -Path (Get-Item -Path "C:\src\*" -Exclude $platforms).FullName -Destination . -Recurse
    New-Item -Path .\windows -ItemType Directory
    Copy-Item -Path (Get-Item -Path "C:\src\windows\*" -Exclude ('flutter')).FullName -Destination .\windows -Recurse
    New-Item -Path .\windows\flutter -ItemType Directory
    Copy-Item -Path (Get-Item -Path "C:\src\windows\flutter\*" -Exclude ('ephemeral')).FullName -Destination .\windows\flutter
}

# If the example app is to be build,
# navigate to the example directory.
if ($example) {
    if (-not (Test-Path -Path example)) {
        throw "no directory named example found in the source"
    }
    Set-Location -Path example
}

# Run clean to remove previous build artifacts.
flutter clean
flutter pub get
# Build the app in release mode.
flutter build windows --release
if ($msix) {
flutter pub run msix:create `
    --build-windows false `
    --install-certificate false
}

# Copy the resulting build directory back to the source directory.
Copy-Item -Path build -Destination C:\src\build_container -Recurse
