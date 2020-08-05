#!/bin/env bash
# baraction.sh for spectrwm status bar

icon() {
    echo -e "+@fn=1;$1+@fn=0;"
}

## DISK
hdd() {
  hdd="$(df -h | awk 'NR==5{print $3, $5}')"
  echo -e "HDD: $hdd"
}

## RAM
mem() {
  mem=`free | awk '/Mem/ {printf "%dM/%dM\n", ($3+$5) / 1024.0, $2 / 1024.0 }'`
  echo -e "$mem"
}

## CPU
cpu() {
  read cpu a b c previdle rest < /proc/stat
  prevtotal=$((a+b+c+previdle))
  sleep 0.5
  read cpu a b c idle rest < /proc/stat
  total=$((a+b+c+idle))
  cpu=$((100*( (total-prevtotal) - (idle-previdle) ) / (total-prevtotal) ))
  echo -e "CPU: $cpu%"
}

## VOLUME
vol() {
    vol=`amixer get Master | awk -F'[][]' 'END{ print $2 }' | sed 's/on://g'`
    echo -e "VOL: $vol"
}

## WIFI
wifi(){
    wifi=`iw dev | grep ssid | awk '{print $2}'`
    echo -e "$wifi"
}

net() {
    eth=$(ip link | grep -m 1 -E '\b(en).*\b(state UP)' | awk '{print substr($2, 1, length($2)-1)}')
    wlan=$(ip link | grep -m 1 -E '\b(wl)' | awk '{print substr($2, 1, length($2)-1)}')
    if [ ! -z "$eth" ] ; then
        echo -e "$eth"
    elif [ ! -z "$wlan" ] ; then
        echo -e "$wlan"
    else
        echo -e "NC"
    fi
}

SLEEP_SEC=1
while :; do
    echo "+@fg=2; $(cpu)+@fg=0; | +@fg=3;  $(mem)+@fg=0; | +@fg=4; $(vol)+@fg=0; | +@fg=5;  $(net)+@fg=0; | "
	sleep $SLEEP_SEC
done
