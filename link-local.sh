#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -l  List of links to create separated by comma
  -p  Path of deployment
  -u  Web user (optional)
  -g  Web group (optional)

Example: ${scriptName} -l /var/www/magento/static/pub/media:pub/media,/var/www/magento/static/pub/static:pub/static,/var/www/magento/static/var:var -p /var/www/magento/releases/12345
EOF
}

trim()
{
  echo -n "$1" | xargs
}

link=
path=
webUser=
webGroup=

while getopts hl:p:u:g:? option; do
  case ${option} in
    h) usage; exit 1;;
    l) link=$(trim "$OPTARG");;
    p) path=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${link}" ]]; then
  echo "No links specified!"
  exit 1
fi

if [[ -z "${path}" ]]; then
  echo "No deploy path specified!"
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

if [[ -n "${link}" ]]; then
    IFS=',' read -r -a linkList <<< "${link}"
    for singleLink in "${linkList[@]}"; do
        IFS=':' read -r -a singleLinkElements <<< "${singleLink}"
        linkTarget="${path}/${singleLinkElements[1]}"
        if [[ -e "${linkTarget}" ]]; then
            if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
                sudo -H -u "${webUser}" bash -c "rm -rf ${linkTarget}"
            else
                rm -rf "${linkTarget}"
            fi
        fi
        linkTargetPath=$(dirname "${linkTarget}")
        if [[ ! -e "${linkTargetPath}" ]]; then
            echo "Creating path: ${linkTargetPath}"
            if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
                sudo -H -u "${webUser}" bash -c "mkdir -p ${linkTargetPath}"
            else
                mkdir -p "${linkTargetPath}"
            fi
        fi
        echo "Linking ${singleLinkElements[0]}:${linkTarget}"
        if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
            sudo -H -u "${webUser}" bash -c "ln -s ${singleLinkElements[0]} ${linkTarget}"
        else
            ln -s "${singleLinkElements[0]}" "${linkTarget}"
        fi
    done
fi
