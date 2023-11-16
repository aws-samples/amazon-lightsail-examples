<script>
    #start audio service
    net start audiosrv
    #set reg key to start narrator at logon
    reg add "HKCU\Software\Microsoft\Windows NT\CurrentVersion\Accessibility" /t REG_SZ /v Configuration /d narrator /f
    #start narrator
    narrator
</script>
#To run the user data scripts every time you reboot or start the instance
<persist>true</persist>