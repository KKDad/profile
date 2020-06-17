#!/bin/bash 

function get_dow() 
{
  DOW=$(date +%u)
  case ${DOW} in
    1) echo "monday";;
    2) echo "tuesday";;
    3) echo "wednesday";;
    4) echo "thursday";;
    5) echo "friday";;
    6) echo "saturday";;
    7) echo "sunday";;
  esac
}

function get_tod() 
{
  TOD=$(date +"%H")
  if [[ $TIME -lt 12 ]]; then
      echo "morning"
  elif [[ $TIME -lt 18 ]]; then
      echo "afternoon"
  else
      echo "evening"
  fi
}

function get_cluster_name()
{
  local NAME=$1
  local FEATURE=$2
  echo "${NAME}-${FEATURE}-$(get_dow)$(get_tod)"
}