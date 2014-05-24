#!/bin/bash

# rundeps
# Runs provided command in the meantime starting required number of socats in
# order to attach to default ports to localhost external services.

# Make sure that any errors cause the script to exit immediately.
set -e

# ## Usage

# Usage message that is displayed when `--help` is given as an argument.
usage() {
  echo "Usage: rundeps some_command --with-args"
  echo "Run a command, but launch service ambassadors before."
  echo
  echo "The rundeps script reads required services from conventional"
  echo "environment variables and starts required number of socats"
  echo "then runs the command."
  echo "Pass the links to the services in form of the"
  echo "env variables like MYSQL_PORT_3306_TCP=tcp://172.17.42.1:3306."
}

# If the --help option is given, show the usage message and exit.
expr -- "$*" : ".*--help" >/dev/null && {
  usage
  exit 0
}

# ## Running commands

# When a process is started, we want to keep track of its pid so we can
# `kill` it when the parent process receives a signal, and so we can `wait`
# for it to finish before exiting the parent process.
store_pid() {
  pids=("${pids[@]}" "$1")
}

# This starts a command asynchronously and stores its pid in a list for use
# later on in the script.
start_command() {
  echo "Running $1"
  bash -c "$1" &
  pid="$!"
  store_pid "$pid"
}

start_commands() {
  while read cmd; do
    start_command "$cmd"
  done
}

# ## Starting socats

# The conventional environment variables must be gathered and parsed
# then used to run socats.
env | grep '_TCP=' | sed 's/.*_PORT_\([0-9]*\)_TCP=tcp:\/\/\(.*\):\(.*\)/socat -ls TCP4-LISTEN:\1,fork,reuseaddr TCP4:\2:\3/' | start_commands

# ## Cleanup

# When a `SIGINT`, `SIGTERM` or `EXIT` is received, this action is run, killing the
# child processes. The sleep stops STDOUT from pouring over the prompt, it
# should probably go at some point.
onexit() {
  echo Exiting
  echo sending SIGTERM to all processes
  kill ${pids[*]} &>/dev/null
  sleep 1
}
trap onexit EXIT

# Run the given command
bash -c "$*"
