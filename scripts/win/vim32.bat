REM @powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin
choco install -y git.installer
choco install -y git
choco install -y vim
choco install -y lua
rem copy lua51.dll in program files
choco install -y python2-x86_32 --version 2.7.9
copy /Y C:\Windows\system32\python27.dll "C:\Program Files\Vim\vim74"
copy /Y "C:\Program Files\Lua\lua51.dll" "C:\Program Files\Vim\Vim74"
choco install -y ctags
