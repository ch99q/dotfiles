#!/bin/bash

source ~/.alias

source ~/.function
source ~/.path
source ~/.env

source ~/.prompt
 
SSHAGENT=/usr/bin/ssh-agent
SSHAGENTARGS="-s"
if [ -z "$SSH_AUTH_SOCK" -a -x "$SSHAGENT" ]; then
    if test -f ~/.ssh-agent-env; then
 eval `cat ~/.ssh-agent-env`
    else
 eval `$SSHAGENT $SSHAGENTARGS` > /bin/null
 trap "kill $SSH_AGENT_PID" 0
    fi
fi