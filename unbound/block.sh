#!/bin/bash

ip=$1
while read domain; do
	unbound-control local_zone "$domain" redirect
	unbound-control local_data "$domain A $ip"
done | while read line; do
	echo -n "${line//ok/+}"
done
echo
