#!/usr/bin/env sh

# Usage: add  _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
# Used to add txt record
dns_dinahosting_add() {
  fulldomain=$1
  txtvalue=$2
  _dinahosting_check_and_set

  hostname="${fulldomain%%.$DINAHOSTING_DomainName}"
  _dina_rest "$(_dinahosting_addtxt "$hostname" "$txtvalue")"
}


# Usage: fulldomain txtvalue
# Used to remove the txt record after validation
dns_dinahosting_rm() {
  fulldomain=$1
  txtvalue=$2
  _dinahosting_check_and_set

  hostname="${fulldomain%%.$DINAHOSTING_DomainName}"
  _dina_rest "$(_dinahosting_deletetxt "$hostname" "$txtvalue")"
}

_dinahosting_check_and_set() {
    DINAHOSTING_Username="${DINAHOSTING_Username:-$(_readaccountconf_mutable DINAHOSTING_Username)}"
  DINAHOSTING_Password="${DINAHOSTING_Password:-$(_readaccountconf_mutable DINAHOSTING_Password)}"
  DINAHOSTING_DomainName="${DINAHOSTING_DomainName:-$(_readaccountconf_mutable DINAHOSTING_DomainName)}"
  if [ -z "$DINAHOSTING_Username" ] || [ -z "$DINAHOSTING_Password" ] || [ -z "$DINAHOSTING_DomainName" ]; then
    DINAHOSTING_Username=""
    DINAHOSTING_Password=""
    DINAHOSTING_DomainName=""
    _err "Please specify DinaHosting username, password and domain name."
    return 1
  fi

  #save the credentials to the account conf file.
  _saveaccountconf_mutable DINAHOSTING_Username "$DINAHOSTING_Username"
  _saveaccountconf_mutable DINAHOSTING_Password "$DINAHOSTING_Password"
  _saveaccountconf_mutable DINAHOSTING_DomainName "$DINAHOSTING_DomainName"
}

# Usage: url
_dina_rest() {
  url=$1
  echo _debug "url=$url"

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
  echo -e "https://dinahosting.com/special/api.php?AUTH_USER=$DINAHOSTING_Username&AUTH_PWD=$DINAHOSTING_Password&responseType=Simple&domain=$DINAHOSTING_DomainName&orderBy=none&command=$command"
}

# Usage: hostname txtvalue
_dinahosting_addtxt() {
  hostname=$1
  txtvalue=$2
  command="Domain_Zone_AddTypeTXT"
  echo -e "$(_dinahosting_base "$command")&hostname=$hostname&text=$txtvalue"
}

# Usage: hostname txtvalue
_dinahosting_deletetxt() {
  hostname=$1
  txtvalue=$2
  command="Domain_Zone_DeleteTypeTXT"
  echo -e "$(_dinahosting_base "$command")&hostname=$hostname&value=$txtvalue"
}

# vim: set sts=2 ts=2 sw=2 et:
