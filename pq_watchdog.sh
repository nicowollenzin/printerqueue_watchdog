#!/bin/bash

while true; do
	if [[ "$(lpq -P Samsung_SCX-4200_Series | tail -n +2 | head -n 1)" != 'no entries' ]]; then
		fhem set printer on-for-timer 320 &>/dev/null
		sleep 25
	fi
	sleep 5
done