---
summary: Style, Tools, Backups, everything I do after a fresh install - nothing much...
---

# Style #
Well, because I forget the settings all the time...
* Color: Default full-red
* Dark mode
* No wallpaper on lock screen
* Default Windows wallpaper
* Lockscreen with Windows Spotlight

# O&O Shut up 10 #
Enable everything except...
* Windows Defender
* Windows SmartScreen
* Updates (recommended < yes)
* Background Apps
* Windows Spotlight (for the lockscreen)
* On some devices make sure to NOT block the microphone or biometrics (fingerprint login)

# Tweaks #
I trust no user. Not even myself - therefore apply this registry patch (name it `Enable additional password request.reg`). It forces even admin users to reenter their passwords...
```
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System]
"ConsentPromptBehaviorAdmin"=dword:00000001
```

# Installers #
I have a server mirroring all my beloved tools - I always map him as Network Drive (for easier usage). Without stored credentials of course...

# Backups #

