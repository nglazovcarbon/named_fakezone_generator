#!/bin/bash

ip=$1
while read domain; do
	if [ "$domain" = 'issuu.com' ]; then
		unbound-control local_zone "$domain" transparent
	else
		unbound-control local_zone "$domain" redirect
	fi
	unbound-control local_data "$domain A $ip"
done | while read line; do
	echo -n "${line//ok/+}"
done
echo
