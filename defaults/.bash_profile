#
# ~/.bash_profile
#

# Global exports

# Creating local bin folder
# If user ID is greater than or equal to 1000 & if ~/.local/bin exists and is a
# directory & if ~/.local/bin is not already in your $PATH
# then export ~/.local/bin to your $PATH.
if [[ $UID -ge 1000 && -d $HOME/.local/bin && -z $(echo $PATH | grep -o $HOME/.local/bin) ]]
then
	export PATH="${PATH}:$HOME/.local/bin"
fi

# Sat Oct 14 2017 11:12: This will set the i3-sensible-terminal to be used:
[ -f /usr/bin/kitty ] && export TERMINAL="kitty"
# Termite has priority over kitty
[ -f /usr/bin/termite ] && export TERMINAL="termite"

export EMAIL="rmolin88@gmail.com"

[ -f /usr/bin/firefox ] && export BROWSER="/usr/bin/firefox"

# Thu Feb 01 2018 05:21: For oracle database crap for school
export ORACLE_HOME=/home/reinaldo/app/reinaldo/product/12.2.0/client_1

export NVIM_LISTEN_ADDRESS=/tmp/nvimsocket

# Ranger load only ~/.config/ranger/rc.conf
export RANGER_LOAD_DEFAULT_RC=FALSE

# Fixes git weird issue
export GIT_TERMINAL_PROMPT=1

# export GDK_SCALE=1.5
# export QT_AUTO_SCREEN_SCALE_FACTOR=1

# Thu Feb 22 2018 08:59: Can't figure out how to set locale properly on arch. Result:
# Wed May 02 2018 04:57: Not needed anymore
# export LANG=en_US.UTF-8

# Exports
# Man settings
export MANPATH=/usr/local/man:/usr/local/share/man:/usr/share/man:/usr/man
# export MANPAGER="nvim -c 'set ft=man' -"

# Adb, fastboot
# Fixes vim-javacomplete2 issues
# Remember to launch nvim at the code base
if [[ `uname -o` != "Android" && -d "$HOME/Downloads/packages/android-sdk-linux" ]]; then
	export ANDROID_HOME=$HOME/Downloads/packages/android-sdk-linux
	export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
fi

# Depends on nvr being installed
# Mon Jun 25 2018 21:51: Basically what this does is to ensure a unique global instance
# of neovim. No matter from where you call nvim. If there is one open it will open files
# there. the original option looked like this:
# export VISUAL="nvr -cc tabedit --remote-wait +'set bufhidden=wipe'"
# However, that wipe will delete the buffer if you exit it. I dont like that.
if [[ -n "$NVIM_LISTEN_ADDRESS" && -f "$HOME/.local/bin/nvr" ]]; then
	export VISUAL="nvr -s $@"
else
	export VISUAL="nvim"
fi

# Allow me to have multiple instances
# alias nvim="$VISUAL"
# export VISUAL=nvim
export EDITOR=$VISUAL

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ -z "$DISPLAY" ] && [ -n "$XDG_VTNR" ] && [ "$XDG_VTNR" -eq 1 ]; then
	exec startx
fi
