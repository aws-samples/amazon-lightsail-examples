# About enable win narrator script

The code in [enable_win_narrator.bat](lightsail-instance-launch-scripts/windows_server/enable_win_narrator.bat) can be used to enable the narrator accessibility feature for visually impaired, so that it always runs on logon.

This is based on [a request in re:Post](https://repost.aws/questions/QUjkaxc6x0QHqzdwr6RxxRWQ/server-accessibility-for-a-visually-impaired#ANs3zh89yiR7S4RRZPNVh14g)

**Note:** this is a simple script that can be used as a part of the launch config.
Learn more [about Windows launch config.](https://docs.aws.amazon.com/lightsail/latest/userguide/create-powershell-script-that-runs-when-you-create-windows-based-instance-in-lightsail.html)

**Note:** to take advantage of the sound on a Lightsail Windows instance, you must use **a native RDP client** that is capable of sound playback from remote machine.