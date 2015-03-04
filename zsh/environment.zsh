# environment.zsh
#
# @package myutilitybelt
# @subpackage zsh
# @author Victor Schröder <schrodervictor@gmail.com>
# @author thiagoalessio <thiagoalessio@me.com>

# Defines vim as the default editor
export EDITOR=vim

# EC2-cli required variables

# Java is a dependency
export JAVA_HOME="/usr/lib/jvm/java-7-openjdk-amd64/jre"

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
