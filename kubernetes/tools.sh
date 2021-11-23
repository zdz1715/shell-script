#!/bin/sh

## log
step()
{
  echo
  echo "# ========================================================= #"
  echo "# $* "
  echo "# ========================================================= #"
}

item() {
  printf '> %s \n' "$1"
}

log()
{
  echo "[$(date +%H:%I:%S)] $1 $2"
}

log_error()
{
  log "[ERROR]" "$*"
}

log_exit()
{
  log "[ERROR]" "$*"
  exit 1
}

log_info()
{
  log "[INFO]" "$*"
}

log_success()
{
  log "[SUCCESS]" "$*"
}

log_warn()
{
  log "[WARN]" "$*"
}

log_command()
{
  log "[COMMAND]" "$*"
  sh -c "$*"
}

## os
get_distribution() {
	lsb_dist=""
	# Every system that we officially support has /etc/os-release
	if [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID" | tr '[:upper:]' '[:lower:]' )"
	fi
	# Returning an empty string here should be alright since the
	# case statements don't act unless you provide an actual value
	if [ -z "$1" ]; then
	  echo "$lsb_dist"
	  return
	fi
  case "$lsb_dist" in

  		ubuntu)
  			if command_exists lsb_release; then
  				dist_version="$(lsb_release --codename | cut -f2)"
  			fi
  			if [ -z "$dist_version" ] && [ -r /etc/lsb-release ]; then
  				dist_version="$(. /etc/lsb-release && echo "$DISTRIB_CODENAME")"
  			fi
  		;;

  		debian|raspbian)
  			dist_version="$(sed 's/\/.*//' /etc/debian_version | sed 's/\..*//')"
  			case "$dist_version" in
  				11)
  					dist_version="bullseye"
  				;;
  				10)
  					dist_version="buster"
  				;;
  				9)
  					dist_version="stretch"
  				;;
  				8)
  					dist_version="jessie"
  				;;
  			esac
  		;;

  		centos|rhel|sles)
  			if [ -z "$dist_version" ] && [ -r /etc/os-release ]; then
  				dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
  			fi
  		;;

  		*)
  			if command_exists lsb_release; then
  				dist_version="$(lsb_release --release | cut -f2)"
  			fi
  			if [ -z "$dist_version" ] && [ -r /etc/os-release ]; then
  				dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
  			fi
  		;;

  	esac
  	echo "$lsb_dist$2$dist_version"
}

is_root() {
  user="$(id -un 2>/dev/null || true)"
  if [ "$user" == 'root' ]; then
    echo true
  else
    echo false
  fi
}

command_exists() {
	command -v "$@" > /dev/null 2>&1
}
