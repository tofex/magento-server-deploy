#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -s  List of scripts separated by comma
  -u  Web user (optional)
  -g  Web group (optional)

Example: ${scriptName} -s /var/www/magento/scripts/one,/var/www/magento/scripts/two
EOF
}

trim()
{
  echo -n "$1" | xargs
}

scripts=
webUser=
webGroup=

while getopts hs:u:g:? option; do
  case ${option} in
    h) usage; exit 1;;
    s) scripts=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${scripts}" ]]; then
  echo "No scripts specified!"
  exit 1
fi

currentUser=$(whoami)
if [[ -z "${webUser}" ]]; then
    webUser="${currentUser}"
fi

if [[ $(which id >/dev/null 2>&1 && echo "yes" || echo "no") == "yes" ]]; then
  currentGroup="$(id -g -n)"
else
  currentGroupId=$(grep "${currentUser}:" /etc/passwd | cut -d':' -f4)
  currentGroup=$(grep ":${currentGroupId}:" /etc/group | cut -d':' -f1)
fi
if [[ -z "${webGroup}" ]]; then
    webGroup="${currentGroup}"
fi

if [[ -n "${scripts}" ]]; then
    IFS=',' read -r -a scriptList <<< "${scripts}"
    for singleScript in "${scriptList[@]}"; do
        echo "Executing: ${singleScript}"
        if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
            sudo -H -u "${webUser}" bash -c "${singleScript}"
        else
            ${singleScript}
        fi
    done
fi
