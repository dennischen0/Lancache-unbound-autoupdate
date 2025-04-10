#!/bin/bash

### Set variables, change as necessary ###
# Username of the regular user you're using
SYSTEMUSER=$(logname)
# Directory the git repository is synced to
GITSYNCDIR=/home/$SYSTEMUSER/cache-domains
# Your personalized config file from "Setting up our config.json file" step
CONFIG=/home/$SYSTEMUSER/config.json

# Create a new, random temp directory and make sure it was created, else exit
TEMPDIR=$(mktemp -d)

  if [ ! -e $TEMPDIR ]; then
      >&2 echo "Failed to create temp directory"
      exit 1
  fi

# Switch to the git directory and pull any new data
cd $GITSYNCDIR && \
  git pull > /dev/null 2>&1

# Copy the .txt files and .json file to the temp directory
cp `find $GITSYNCDIR -name "*.txt" -o -name cache_domains.json` $TEMPDIR

# Copy the create-unbound.sh script to our temp directory
mkdir $TEMPDIR/scripts/ && \
  cp $GITSYNCDIR/scripts/create-unbound.sh $TEMPDIR/scripts/ && \
  chmod +x $TEMPDIR/scripts/create-unbound.sh

# Copy the config over
cp $CONFIG $TEMPDIR/scripts/

# Generate the unbound files with the script
cd $TEMPDIR/scripts/ && \
  bash ./create-unbound.sh > /dev/null 2>&1

# Copy the unbound files
cp -r $TEMPDIR/scripts/output/unbound/*.conf /etc/unbound/unbound.conf.d/

# Restart unbound
if systemctl is-active --quiet unbound ; then
  sudo service unbound restart
fi

# Delete the temp directory to clean up files
trap "exit 1"           HUP INT PIPE QUIT TERM
trap 'rm -rf "$TEMPDIR"' EXIT
