# environment.zsh
#
# @package myutilitybelt
# @subpackage zsh
# @author Victor Schröder <schrodervictor@gmail.com>
# @author thiagoalessio <thiagoalessio@me.com>

# Defines vim as the default editor
export EDITOR=vim

# Several Java settings
OPT_JAVA="/opt/jdk/current"
if [[ -L "$OPT_JAVA" && -d "$OPT_JAVA" ]]; then
    export JAVA_HOME="$OPT_JAVA"
fi

if [[ "$JAVA_HOME" && "$PATH" != *"$JAVA_HOME"* ]]; then
    export PATH="$JAVA_HOME/bin:$PATH"
fi

OPT_MAVEN="/opt/maven/current"
if [[ -L "$OPT_MAVEN" && -d "$OPT_MAVEN" ]]; then
    export MAVEN_HOME="$OPT_MAVEN"
fi

if [[ "$MAVEN_HOME" && "$PATH" != *"$MAVEN_HOME"* ]]; then
    export PATH="$MAVEN_HOME/bin:$PATH"
fi

OPT_SCALA="/opt/scala/current"
if [[ -L "$OPT_SCALA" && -d "$OPT_SCALA" ]]; then
    export SCALA_HOME="$OPT_SCALA"
fi

if [[ "$SCALA_HOME" && "$PATH" != *"$SCALA_HOME"* ]]; then
    export PATH="$SCALA_HOME/bin:$PATH"
fi

OPT_SBT="/opt/sbt/current"
if [[ -L "$OPT_SBT" && -d "$OPT_SBT" ]]; then
    export SBT_HOME="$OPT_SBT"
fi

if [[ "$SBT_HOME" && "$PATH" != *"$SBT_HOME"* ]]; then
    export PATH="$SBT_HOME/bin:$PATH"
fi

# Nix is a nice functional package manager, let's use it
if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then
    . $HOME/.nix-profile/etc/profile.d/nix.sh;
fi

etc_git_control() {
    if [[ -z "$1" ]]; then
        echo '[/etc changes report]'
        sudo git -C /etc status
    else
        echo '[/etc commit report]'
        sudo git -C /etc add .
        sudo git -C /etc commit -m "$1"
    fi
}
