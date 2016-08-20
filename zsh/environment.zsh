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

# EC2-cli required variables
FIND_JAVA_RECURSION_LIMIT=10
# Custom function to search for the appropriate java home and
# export the environmental variable
find_and_export_java_home() {

    (( FIND_JAVA_RECURSION_LIMIT-- ))
    if [[ $FIND_JAVA_RECURSION_LIMIT -eq 0 ]]; then
        echo 'Reached recursion limit for setting JAVA_HOME!!'
        return 1
    fi

    # The first parameter is the reference we want to follow
    # If nothing is passed, the default will be the initial
    # java symbolic link (normally /usr/bin/java)
    local LINK=${1:-$(which java)}

    # This is for check the nature of what the current link is pointing
    # (if it is a link, of course)
    #
    # Link is something like this:
    #     /usr/bin/java: symbolic link to `/etc/alternatives/java'
    #
    # Binary looks like that:
    #     /usr/lib/jvm/java-7-openjdk-amd64/jre/bin/java: ELF 64-bit LSB  \
    #     executable, x86-64, version 1 (SYSV), dynamically linked (uses \
    #     shared libs), for GNU/Linux 2.6.24, \
    #     BuildID[sha1]=c4f9823dcf7d0d5401bff9928597bd3113093925, stripped
    #
    LINK_ENDPOINT=$(file "$LINK")

    # Check if the reference is a symbolic link
    if [[ $LINK_ENDPOINT == *"symbolic link to"* ]]; then

        # If yes, call the function recursively
        #
        # The expansion is taking only the last part of the result of
        # the `file` command (the path of wherever the link is pointing)
        TEMP="${LINK_ENDPOINT##*symbolic link to }"
        find_and_export_java_home "$TEMP"
    else
        # If negative, we've found the binary. In this case we export the
        # variable, stripping out the '/bin/java' at the end of the string
        export JAVA_HOME="${LINK%/bin/java}"
    fi

}

# Java is a dependency
# If the JAVA_HOME is not defined already, call our custom function
if [[ -z "$JAVA_HOME" ]]; then
    find_and_export_java_home
fi

set_ec2_credentials_from_csv() {

    local DEFAULT_CSV="$HOME/.aws/credentials.csv"

    if [[ -z "$1" && -f "$DEFAULT_CSV" ]]; then
        # AWS credentials variables for EC2-cli
        # Define where the aws csv credentials file is located
        AWS_CREDENTIALS_CSV="$DEFAULT_CSV"
    elif [[ -f "$1" ]]; then
        AWS_CREDENTIALS_CSV="$1"
    else
        echo "CSV file not fount!"
        exit 1
    fi

    # Appending the EC2-cli binaries folder to the path
    # These next lines assume that the current version of the EC2 tool
    # has a symbolic link at /usr/local/share/ec2/current
    export EC2_HOME="/usr/local/share/ec2/current"
    export PATH=$PATH:$EC2_HOME/bin

    # Read the credentials from the file
    read -r AWS_ACCESS_KEY AWS_SECRET_KEY <<< $(awk -F, 'NR==2 { print $2" "$3 }' $AWS_CREDENTIALS_CSV)
    # Export the variables
    export AWS_ACCESS_KEY
    export AWS_SECRET_KEY

    # Define the default AWS region to Frankfurt (eu-central-1)
    export EC2_URL=https://ec2.eu-central-1.amazonaws.com

}

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
