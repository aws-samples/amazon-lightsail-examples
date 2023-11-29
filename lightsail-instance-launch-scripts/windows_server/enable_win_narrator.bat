echo net start audiosrv > c:\run_narrator.bat
echo start narrator >> c:\run_narrator.bat
powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%userprofile%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\run_narrator.lnk');$s.TargetPath='c:\run_narrator.bat';$s.Save()"