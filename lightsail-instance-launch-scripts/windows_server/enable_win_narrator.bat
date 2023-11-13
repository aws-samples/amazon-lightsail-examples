# The code below can be used enable accessibility for a visually impaired feature of narrator and runs it always on logon.
# This is based on a request on re:post https://repost.aws/questions/QUjkaxc6x0QHqzdwr6RxxRWQ/server-accessibility-for-a-visually-impaired#ANs3zh89yiR7S4RRZPNVh14g
# Note that this is a simple script that can be used as a part of the launch config.
# Note: To take advantage of the sound on the lightsail instance a native RDP client which can playback sound from remote machine should be used to connect.
<script>
    net start audiosrv
    reg add "HKCU\Software\Microsoft\Windows NT\CurrentVersion\Accessibility" /t REG_SZ /v Configuration /d narrator /f
    narrator
</script>