#!/bin/bash

set -eu

fakezoneroot=/opt/named_fakezone_generator/unbound/

current_config="$1"
new_list="$2"
ip="$3"

CURRENT_DOMAINS=/tmp/current_domains
NEW_DOMAINS=/tmp/new_domains

[ -s $current_config -a -s $new_list ]

egrep "(transparent|redirect)$" "$current_config" | awk '{print $2}' | tr -d '"' | LANG= sort -u > $CURRENT_DOMAINS
$fakezoneroot/generate_unbound_configs.sh /tmp/reductor.https.resolv 127.0.0.1 process_list < $new_list | LANG= sort -u > $NEW_DOMAINS 
LANG= join -a1 -v1 -j1 $CURRENT_DOMAINS $NEW_DOMAINS | $fakezoneroot/unblock.sh
LANG= join -a1 -v1 -j1 $NEW_DOMAINS $CURRENT_DOMAINS | $fakezoneroot/block.sh "$ip"
