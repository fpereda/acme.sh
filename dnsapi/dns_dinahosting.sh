#!/usr/bin/env sh

# Usage: add  _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
# Used to add txt record
dns_dinahosting_add() {
  fulldomain=$1
  txtvalue=$2
  _dinahosting_check_and_set
  hostname="$(_dinahosting_get_hostname "$fulldomain")"
  if [ -z "$hostname" ] ; then
    _err "Could not parse $fulldomain into hostname and domainname."
    return 1
  fi

  domainname="${fulldomain#$hostname.}"
  _debug "hostname=$hostname domainname=$domainname"
  _dina_rest "$(_dinahosting_addtxt "$hostname" "$domainname" "$txtvalue")"
}


# Usage: fulldomain txtvalue
# Used to remove the txt record after validation
dns_dinahosting_rm() {
  fulldomain=$1
  txtvalue=$2
  _dinahosting_check_and_set
  hostname="$(_dinahosting_get_hostname "$fulldomain")"
  if [ -z "$hostname" ] ; then
    _err "Could not parse $fulldomain into hostname and domainname."
    return 1
  fi

  domainname="${fulldomain#$hostname.}"
  _dina_rest "$(_dinahosting_deletetxt "$hostname" "$domainname" "$txtvalue")"
}

# Usage: fulldomain
_dinahosting_get_hostname() {
  fulldomain=$1
  _dina_rest "$(_dinahosting_base "Services_GetDomains")"
  printf "%s" "$response" \
    | sed -n -e "/^.*_domain = '\([^']*\)'$/s--\1-gp" \
    | while read registereddomain ; do
        parsedhostname="${fulldomain%.$registereddomain}"
        if [ "$parsedhostname" != "$fulldomain" ] ; then
          echo -e "$parsedhostname"
        fi
      done
  return 0
}

_dinahosting_check_and_set() {
  DINAHOSTING_Username="${DINAHOSTING_Username:-$(_readaccountconf_mutable DINAHOSTING_Username)}"
  DINAHOSTING_Password="${DINAHOSTING_Password:-$(_readaccountconf_mutable DINAHOSTING_Password)}"
  if [ -z "$DINAHOSTING_Username" ] || [ -z "$DINAHOSTING_Password" ]; then
    DINAHOSTING_Username=""
    DINAHOSTING_Password=""
    _err "Please specify DinaHosting username and password."
    return 1
  fi

  #save the credentials to the account conf file.
  _saveaccountconf_mutable DINAHOSTING_Username "$DINAHOSTING_Username"
  _saveaccountconf_mutable DINAHOSTING_Password "$DINAHOSTING_Password"
}

# Usage: url
_dina_rest() {
  url=$1
  _debug "url=$url"

  response=$(_get "$url")

  if [ "$?" != "0" ] ; then
    _err "error $ep"
    return 1
  fi

  if ! printf "%s" "$response" | grep "message = 'Success.'" >/dev/null; then
    _err "Error"
    return 1
  fi

  return 0
}

# Usage: command
_dinahosting_base() {
  command=$1
  echo -e "https://dinahosting.com/special/api.php?AUTH_USER=$DINAHOSTING_Username&AUTH_PWD=$DINAHOSTING_Password&responseType=Simple&command=$command"
}

# Usage: hostname domainname txtvalue
_dinahosting_addtxt() {
  hostname=$1
  domainname=$2
  txtvalue=$3
  command="Domain_Zone_AddTypeTXT"
  echo -e "$(_dinahosting_base "$command")&orderBy=none&domain=$domainname&hostname=$hostname&text=$txtvalue"
}

# Usage: hostname domainname txtvalue
_dinahosting_deletetxt() {
  hostname=$1
  domainname=$2
  txtvalue=$3
  command="Domain_Zone_DeleteTypeTXT"
  echo -e "$(_dinahosting_base "$command")&orderBy=none&domain=$domainname&hostname=$hostname&value=$txtvalue"
}

# vim: set sts=2 ts=2 sw=2 et:
