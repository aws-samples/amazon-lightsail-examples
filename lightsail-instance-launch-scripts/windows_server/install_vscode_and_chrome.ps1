<powershell>

# Download and install Chocolatey to do unattended installations of the rest of the apps.
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Create a log-monitoring script to monitor the progress of the Launch script execution
$myscript = @"
get-content C:\ProgramData\Amazon\EC2-Windows\launch\Log\UserdataExecution.log -wait
"@

# Save the log-monitoring script to the desktop for the user
$myscript | out-file -FilePath C:\Users\Administrator\Desktop\MonitorLogs.ps1 -Encoding utf8 -Force

# Install Visual Studio Code (VSCode) and Google Chrome 
choco install -y vscode --force --force-dependencies
choco install -y googlechrome --force --force-dependencies

</powershell>
<persist>false</persist>
