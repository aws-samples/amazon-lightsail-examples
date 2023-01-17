# The code below will create a file on the desktop called 'MonitorLogs'. once you login to your Windows
# Instance you can right-click the file on the desktop and click 'open with PowerShell' to watch the progress of
# Any more lines of code in the launch script will be reflected here.
<powershell>

# Create a log-monitoring script to monitor the progress of the Launch script execution
$myscript = @"
get-content C:\ProgramData\Amazon\EC2-Windows\launch\Log\UserdataExecution.log -wait
"@

# Save the log-monitoring script to the desktop for the user
$myscript | out-file -FilePath C:\Users\Administrator\Desktop\MonitorLogs.ps1 -Encoding utf8 -Force

</powershell>
<persist>false</persist>
