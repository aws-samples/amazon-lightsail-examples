<script>
    net start audiosrv

    reg add "HKCU\Software\Microsoft\Windows NT\CurrentVersion\Accessibility" /t REG_SZ /v Configuration /d narrator /f

    narrator
</script>

<persist>true</persist>