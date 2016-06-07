#!/bin/bash

while read domain; do
	unbound-control local_zone_remove "$domain"
done | while read line; do
        echo -n "${line//ok/-}"
done
echo

