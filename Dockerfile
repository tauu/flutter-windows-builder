# escape=`

# Create a windows container and install VisualStudio in it.
# This part is based on the official example from Microsoft.
# https://docs.microsoft.com/en-us/visualstudio/install/build-tools-container?view=vs-2022
FROM mcr.microsoft.com/windows/servercore:ltsc2019

# Defione the version of flutter, which will be installed in the container.
ARG FLUTTER_VERSION=2.10.3

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

RUN `
    # Download the Build Tools bootstrapper.
    curl -SL --output vs_buildtools.exe https://aka.ms/vs/17/release/vs_buildtools.exe `
    `
    # Install Build Tools required for Native C++ Desktop Apps.
    # The list of components and workloads has been adapted from 
    #   https://git.openprivacy.ca/openprivacy/flutter-desktop
    # Some components from their list was removed,
    # as they did not seem to be necessary.
    && (start /w vs_buildtools.exe --quiet --wait --norestart --nocache `
        --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools" `
        --add Microsoft.VisualStudio.Workload.VCTools `
        --add Microsoft.VisualStudio.Component.Windows10SDK.19041 `
        --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        --add Microsoft.VisualStudio.Component.VC.CMake.Project `
        --add Microsoft.VisualStudio.Workload.NativeDesktop `
        --add Microsoft.VisualStudio.Component.VC.CLI.Support `
        --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 `
        --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 `
        --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 `
        --remove Microsoft.VisualStudio.Component.Windows81SDK `
        || IF "%ERRORLEVEL%"=="3010" EXIT 0) `
    `
    # Cleanup
    && del /q vs_buildtools.exe

# Install Google Root R1 cert so pub.dartlang.org keeps working.
ADD https://pki.goog/repo/certs/gtsr1.pem C:/TEMP/gtsr1.pem
RUN powershell.exe -Command `
        Import-Certificate -FilePath C:\TEMP\gtsr1.pem -CertStoreLocation Cert:\LocalMachine\Root

# Install Flutter into C:\flutter and enable the windows desktop platform.
RUN setx path "%path%;C:\flutter\bin;C:\flutter\bin\cache\dart-sdk\bin;"
ADD https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_${FLUTTER_VERSION}-stable.zip C:\TEMP\flutter_windows.zip
RUN powershell.exe -Command Expand-Archive -LiteralPath C:\TEMP\flutter_windows.zip -DestinationPath C:\
RUN flutter config --no-analytics
RUN flutter config --enable-windows-desktop

# Cleanup
RUN del /q C:\TEMP\*.*

# Show the current state of the flutter installation after the installation.
# This should display no errors for the windows desktop environment.
RUN flutter doctor -v

# Add a powershell script, which will compile a flutter app mounted at C:\src.
# The built app is copied to the folder build_container within the mounted folder.
COPY build.ps1 C:\build.ps1
WORKDIR C:\build
VOLUME [ "C:\\src" ]
ENTRYPOINT [ "powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';", "C:\\build.ps1"]