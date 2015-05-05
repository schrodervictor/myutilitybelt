# environment.zsh
#
# @package myutilitybelt
# @subpackage zsh
# @author Victor Schröder <schrodervictor@gmail.com>
# @author thiagoalessio <thiagoalessio@me.com>

# Defines vim as the default editor
export EDITOR=vim


# EC2-cli required variables

# Custom function to search for the appropriate java home and
# export the environmental variable
find_and_export_java_home() {

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
    if [[ $LINK_ENDPOINT == *"symbolic link"* ]]; then

        # If yes, call the function recursively
        #
        # The expansion is taking only the last part of the result of
        # the `file` command (the path of wherever the link is pointing)
        find_and_export_java_home "${${LINK_ENDPOINT##*\`}:0:-2}"
    else
        # If negative, we've found the binary. In this case we export the
        # variable, stripping out the '/bin/java' at the end of the string
        export JAVA_HOME="${LINK%/bin/java}"
    fi

}

# Java is a dependency
# If the JAVA_HOME is not defined already, call our custom function
if [[ ! -z "$JAVA_HOME" ]]; then
    find_and_export_java_home
fi

# Appending the EC2-cli binaries folder to the path
export EC2_HOME="/usr/local/ec2/ec2-api-tools-1.7.3.0"
export PATH=$PATH:$EC2_HOME/bin

# AWS credentials variables for EC2-cli
# Define where the aws csv credentials file is located
AWS_CREDENTIALS_CSV=$HOME/.aws/credentials.csv
# Read the credentials from the file
read -r AWS_ACCESS_KEY AWS_SECRET_KEY <<< $(awk -F, 'NR==2 { print $2" "$3 }' $AWS_CREDENTIALS_CSV)
# Export the variables
export AWS_ACCESS_KEY
export AWS_SECRET_KEY


# Nix is a nice functional package manager, let's use it
if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then
    . $HOME/.nix-profile/etc/profile.d/nix.sh;
fi
