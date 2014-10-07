#! /bin/bash

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
PID_FILE=$ROOT/logs/buildAgent.pid

ARGS="$@"
AGENT_SCRIPT=$($ROOT/agent.sh $ARGS >/dev/null 2>&1; echo $?)

if [ "$AGENT_SCRIPT" == "1" ];
then
  echo "agent script failed, checking for pid file $PID_FILE"
  if [ -f "$PID_FILE" ];
  then
    ps -p $(cat "$PID_FILE") >/dev/null 2>&1
    AGENT_PROC=$?
    if [ "$AGENT_PROC" == "1" ];
    then
      echo "pid exists but agent not running"
      exit 1
    else
      echo "agent running as pid $AGENT_PROC"
      exit 0
    fi
  else
    echo "agent pid does not exist"
    exit 1
  fi
else
  echo "agent started successfully"
  exit 0
fi
