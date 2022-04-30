#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -p  Path of deployment
  -w  Web path
  -u  Web user (optional)
  -g  Web group (optional)

Example: ${scriptName} -p /var/www/magento/releases/12345 -w /var/www/magento/htdocs
EOF
}

trim()
{
  echo -n "$1" | xargs
}

path=
webPath=
webUser=
webGroup=

while getopts hp:w:u:g:? option; do
  case ${option} in
    h) usage; exit 1;;
    p) path=$(trim "$OPTARG");;
    w) webPath=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${path}" ]]; then
  echo "No deploy path specified!"
  exit 1
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  exit 1
fi

currentUser=$(whoami)
if [[ -z "${webUser}" ]]; then
  webUser="${currentUser}"
fi

currentGroup=$(id -g -n)
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

echo "Removing link to previous release at: ${webPath}"
if [[ -e "${webPath}" ]]; then
  if [[ -L "${webPath}" ]]; then
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      result=$(sudo -H -u "${webUser}" bash -c "rm ${webPath}" 2>/dev/null && echo "1" || echo "0")
      if [[ "${result}" -eq 0 ]]; then
        result=$(sudo -H -u "${webUser}" bash -c "sudo rm ${webPath}" 2>/dev/null && echo "1" || echo "0")
        if [[ "${result}" -eq 0 ]]; then
          rm "${webPath}"
        fi
      fi
    else
      rm "${webPath}"
    fi
  else
    if [ -n "$(find "${webPath}" -mindepth 1 -not -type l)" ]; then
      echo "Web path already exists not as link, create backup"
      if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
        set +e
        if ! sudo -H -u "${webUser}" bash -c "mv ${webPath} ${webPath}_$(date +'%Y_%m_%d_%H_%M_%S')" 2>/dev/null; then
          set -e
          sudo -H -u "${webUser}" bash -c "sudo mv ${webPath} ${webPath}_$(date +'%Y_%m_%d_%H_%M_%S')"
        fi
        set -e
      else
        mv "${webPath}" "${webPath}_$(date +'%Y_%m_%d_%H_%M_%S')"
      fi
    else
      echo "Web path already exists, but can be deleted because it is empty"
      if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "rm -rf ${webPath}"
      else
        rm -rf "${webPath}"
      fi
    fi
  fi
fi

echo "Linking release from: ${path} to: ${webPath}"
if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
  result=$(sudo -H -u "${webUser}" bash -c "ln -s ${path} ${webPath}" 2>/dev/null && echo "1" || echo "0")
  if [[ "${result}" -eq 0 ]]; then
    result=$(sudo -H -u "${webUser}" bash -c "sudo ln -s ${path} ${webPath}" 2>/dev/null && echo "1" || echo "0")
    if [[ "${result}" -eq 0 ]]; then
      ln -s "${path}" "${webPath}"
    fi
    chownResult=$(sudo -H -u "${webUser}" bash -c "sudo chown -R ${webUser}:${webGroup} ${webPath}" 2>/dev/null && echo "1" || echo "0")
    if [[ "${chownResult}" -eq 0 ]]; then
      sudo chown -R "${webUser}:${webGroup}" "${webPath}"
    fi
  fi
else
  ln -s "${path}" "${webPath}"
fi
