<script>
    #create a new startup script statup_script.bat and  add start audio service to the script
    echo net start audiosrv > c:\startup_script.bat
    #add start narrator
    echo narrator >> c:\startup_script.bat
    #add exit cmd window
    echo exit >> c:\startup_script.bat
    #create shortcut to startup_script.bat in AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\ to run the script everytime
    powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%userprofile%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\startup_script.lnk');$s.TargetPath='c:\startup_script.bat';$s.Save()"
</script>