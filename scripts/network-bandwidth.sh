#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"


get_bandwidth_for_osx() {
  python3 "$CURRENT_DIR/bandwidth.py"
}

get_bandwidth_for_linux() {
  netstat -ie | awk '
    match($0, /RX([[:space:]]packets[[:space:]][[:digit:]]+)?[[:space:]]+bytes[:[:space:]]([[:digit:]]+)/, rx) { rx_sum+=rx[2]; }
    match($0, /TX([[:space:]]packets[[:space:]][[:digit:]]+)?[[:space:]]+bytes[:[:space:]]([[:digit:]]+)/, tx) { tx_sum+=tx[2]; }
    END { print rx_sum, tx_sum }
  '
}

get_bandwidth() {
  local os="$1"

  case $os in
    osx)
      echo -n $(get_bandwidth_for_osx)
      return 0
      ;;
    linux)
      echo -n $(get_bandwidth_for_linux)
      return 0
      ;;
    *)
      echo -n "0 0"
      return 1
      ;;
  esac
}

format_speed() {
  if [ $1 -lt 1048576 ]; then
    awk -v num=$1 'BEGIN{printf "%.1fkB/s", num/1024}'
  elif [ $1 -lt 1073741824 ]; then
    awk -v num=$1 'BEGIN{printf "%.1fMB/s", num/1048576}'
  else
    awk -v num=$1 'BEGIN{printf "%.1fGB/s", num/1073741824}'
  fi
}

main() {
  local sleep_time=$(get_tmux_option "status-interval")
  local old_value=$(get_tmux_option "@network-bandwidth-previous-value")

  if [ -z "$old_value" ]; then
    $(set_tmux_option "@network-bandwidth-previous-value" "-")
    echo -n "Please wait..."
    return 0
  else
    local os=$(os_type)
    local first_measure=( $(get_bandwidth $os) )
    sleep $sleep_time
    local second_measure=( $(get_bandwidth $os) )
    local download_speed=$(((${second_measure[0]} - ${first_measure[0]}) / $sleep_time))
    local upload_speed=$(((${second_measure[1]} - ${first_measure[1]}) / $sleep_time))
    $(set_tmux_option "@network-bandwidth-previous-value" " $(format_speed $download_speed)   $(format_speed $upload_speed)")
  fi

  echo -n "$(get_tmux_option "@network-bandwidth-previous-value")"
}

main
