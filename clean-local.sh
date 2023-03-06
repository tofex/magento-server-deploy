#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -d  Deploy base path
  -c  Number of histories to keep (default: 5)
  -u  Web user (optional)
  -g  Web group (optional)

Example: ${scriptName} -d /var/www/magento/releases -c 3
EOF
}

trim()
{
  echo -n "$1" | xargs
}

deployPath=
deployHistoryCount=
webUser=
webGroup=

while getopts hd:c:u:g:? option; do
  case ${option} in
    h) usage; exit 1;;
    d) deployPath=$(trim "$OPTARG");;
    c) deployHistoryCount=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${deployPath}" ]]; then
  echo "No deploy base path specified!"
  exit 1
fi

if [[ -z "${deployHistoryCount}" ]]; then
  deployHistoryCount=5
fi

currentUser=$(whoami)
if [[ -z ${webUser} ]]; then
  webUser=${currentUser}
fi

if [[ $(which id >/dev/null 2>&1 && echo "yes" || echo "no") == "yes" ]]; then
  currentGroup="$(id -g -n)"
else
  currentGroupId=$(grep "${currentUser}:" /etc/passwd | cut -d':' -f4)
  currentGroup=$(grep ":${currentGroupId}:" /etc/group | cut -d':' -f1)
fi
if [[ -z ${webGroup} ]]; then
  webGroup=${currentGroup}
fi

if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
  oldReleases=( $(sudo -H -u "${webUser}" bash -c "find ${deployPath} -mindepth 1 -maxdepth 1 -type d | sort | head -n -${deployHistoryCount}") )
  for oldRelease in "${oldReleases[@]}"; do
    echo "Removing previous release: ${oldRelease}"
    result=$(sudo -H -u "${webUser}" bash -c "rm -rf ${oldRelease}" 2>/dev/null && echo "1" || echo "0")
    if [[ ${result} -eq 0 ]]; then
      result=$(sudo -H -u "${webUser}" bash -c "sudo rm -rf ${oldRelease}" 2>/dev/null && echo "1" || echo "0")
      if [[ ${result} -eq 0 ]]; then
        rm -rf "${oldRelease}"
      fi
    fi
  done
else
  oldReleases=( $(find "${deployPath}" -mindepth 1 -maxdepth 1 -type d | sort | head -n -"${deployHistoryCount}") )
  for oldRelease in "${oldReleases[@]}"; do
    echo "Removing previous release: ${oldRelease}"
    rm -rf "${oldRelease}"
  done
fi
