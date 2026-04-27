#!/bin/bash

RIPE_URL="https://stat.ripe.net/data/country-resource-list/data.json?resource=ru"
RIPE_DATABASE="./ripe.json"
RIPE_DATABASE_VALID_SECONDS=2592000

NET_GATEWAY="$(ip route show default | awk '{print $3}')"
NET_DEVICE="$(ip route show default | awk '{print $5}')"

VPN_GATEWAY="10.9.0.1"
VPN_DEVICE="xray0"

STOP_FILE="./stop.sh"

unset_address4() {
  address="$(ip -4 address show dev "$VPN_DEVICE" | grep inet | awk '{print $2}')"
  if [[ -n "$address" ]]; then
    echo "interface $VPN_DEVICE ipv4 address $address found"

    ip address del dev "$VPN_DEVICE" "$address"

    if (( $? == 0 )); then
      echo "unset ipv4 address of interface $VPN_DEVICE from $address"
    else
      echo "can't unset ipv4 address of interface $VPN_DEVICE from $address"
    fi
  fi
}

unset_address6() {
  address="$(ip -6 address show dev "$VPN_DEVICE" | grep inet6 | awk '{print $2}')"
  if [[ -n "$address" ]]; then
    echo "interface $VPN_DEVICE ipv6 address $address found"

    ip address del dev "$VPN_DEVICE" "$address"

    if (( $? == 0 )); then
      echo "unset ipv6 address of interface $VPN_DEVICE from $address"
    else
      echo "can't unset ipv6 address of interface $VPN_DEVICE from $address"
    fi
  fi
}

set_address4() {
  ip address add dev "$VPN_DEVICE" "$VPN_GATEWAY/24"

  if (( $? == 0 )); then
    echo "set ipv4 address of interface $VPN_DEVICE to $VPN_GATEWAY/24"
  else
    echo "can't set ipv4 address of interface $VPN_DEVICE to $VPN_GATEWAY/24"
  fi
}

update_geoip() {
  if [[ -f "$RIPE_DATABASE" ]]; then
    echo "geoip database found"
    if (( "$(date --universal --reference "$RIPE_DATABASE" "+%s")" + "$RIPE_DATABASE_VALID_SECONDS" >= "$(date --universal "+%s")" )); then
      echo "geoip database is up-to-date"
    else
      echo "geoip database update required"

      update_ripe
    fi
  else
    echo "geoip database not found"
    echo "geoip database update required"

    update_ripe

    if (( $? > 0 )); then
      exit 1;
    fi
  fi
}

update_ripe() {
  curl --silent --interface "$VPN_DEVICE" --location --request "GET" --output "$RIPE_DATABASE.tmp" --max-time "10" "$RIPE_URL" && \

  if (( "$?" == "0" )); then
    [[ -f "$RIPE_DATABASE" ]] && mv -v "$RIPE_DATABASE" "$RIPE_DATABASE.old"
    [[ -f "$RIPE_DATABASE.tmp" ]] && mv -v "$RIPE_DATABASE.tmp" "$RIPE_DATABASE"

    echo "ripe database updated"
    return 0
  else
    rm "$RIPE_DATABASE.tmp"

    echo "ripe database not updated"
    return 1
  fi
}

main() {
  unset_address4
  unset_address6

  set_address4

  update_geoip

  echo "#!/bin/bash" > "$STOP_FILE"

  chmod +x "$STOP_FILE"

  echo "ip route del 0.0.0.0/0 via $VPN_GATEWAY dev $VPN_DEVICE" >> "$STOP_FILE"

  for item in $(cat "$RIPE_DATABASE" | jq --raw-output ".data.resources.ipv4" | jq --raw-output ".[]"); do
    if [[ "$item" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
      # subnet
      echo "ip route add $item via $NET_GATEWAY dev $NET_DEVICE"
      ip route add "$item" via "$NET_GATEWAY" dev "$NET_DEVICE"
      echo "ip route del $item via $NET_GATEWAY dev $NET_DEVICE" >> "$STOP_FILE"
    elif [[ "$item" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
      # range

      # octet & prefix
      octet=""
      prefix=""
      for i in $(seq "1" "4"); do
        first="$(echo "$item" | awk -F '-' '{print $1}' | awk -F '.' "{print \$$i}")"
        second="$(echo "$item" | awk -F '-' '{print $2}' | awk -F '.' "{print \$$i}")"
	if [[ "$first" != "$second" ]]; then
          octet="$i"
	  break
	else
          prefix="${prefix}${first}."
	  continue
	fi
      done

      # postfix
      postfix="/24"
      for i in $(seq "$(( $octet + "1" ))" "4" ); do
        postfix=".0${postfix}"
      done

      for i in $(seq "$first" "$second" ); do
        echo "ip route add ${prefix}${i}${postfix} via $NET_GATEWAY dev $NET_DEVICE"
        ip route add "${prefix}${i}${postfix}" via "$NET_GATEWAY" dev "$NET_DEVICE"
        echo "ip route del ${prefix}${i}${postfix} via $NET_GATEWAY dev $NET_DEVICE" >> "$STOP_FILE"
      done
    else
      # unknown
      echo "unknown $item"
    fi
  done

  echo "ip route add 0.0.0.0/0 via $VPN_GATEWAY dev $VPN_DEVICE"
  ip route add "0.0.0.0/0" via "$VPN_GATEWAY" dev "$VPN_DEVICE"
}

main
