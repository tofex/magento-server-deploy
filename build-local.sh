#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -a  Archive to deploy
  -p  Path to deploy to
  -u  Web user (optional)
  -g  Web group (optional)

Example: ${scriptName} -a /var/www/magento/builds/development.tar.gz -p /var/www/magento/releases/12345
EOF
}

trim()
{
  echo -n "$1" | xargs
}

archive=
path=
webUser=
webGroup=

while getopts ha:p:u:g:? option; do
  case ${option} in
    h) usage; exit 1;;
    a) archive=$(trim "$OPTARG");;
    p) path=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${archive}" ]]; then
  echo "No archive to deploy specified!"
  exit 1
fi

if [[ -z "${path}" ]]; then
  echo "No path specified!"
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

echo "Creating deploy path: ${path}"
set +e
if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
  if ! sudo -H -u "${webUser}" bash -c "mkdir -p ${path} 2>/dev/null"; then
    sudo -H -u "${webUser}" bash -c "sudo mkdir -p ${path} 2>/dev/null"
    sudo -H -u "${webUser}" bash -c "sudo chown ${currentUser}:${currentGroup} ${path} 2>/dev/null"
  fi
else
  if ! mkdir -p "${path}" 2>/dev/null; then
    sudo mkdir -p "${path}" 2>/dev/null
    sudo chown "${currentUser}":"${currentGroup}" "${path}" 2>/dev/null
  fi
fi
set -e

echo "Copy build archive from: ${archive} to deploy path"
if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
  sudo -H -u "${webUser}" bash -c "cp ${archive} ${path}"
else
  cp "${archive}" "${path}"
fi

fileName=$(basename "${archive}")

cd "${path}"

echo "Extracting build archive: ${fileName}"
if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
  sudo -H -u "${webUser}" bash -c "tar -xf ${fileName} | cat"
  if [[ ! -f bin/magento ]]; then
    sudo -H -u "${webUser}" bash -c "touch maintenance.flag"
  fi
else
  tar -xf "${fileName}" | cat
  if [[ ! -f bin/magento ]]; then
    touch maintenance.flag
  fi
fi

echo "Removing copied build archive: ${fileName}"
if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
  sudo -H -u "${webUser}" bash -c "rm -rf ${fileName}"
else
  rm -rf "${fileName}"
fi
