#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -d  Deploy Id (used as directory name)

Example: ${scriptName} -d 12345
EOF
}

trim()
{
  echo -n "$1" | xargs
}

deployId=

while getopts hv:d:? option; do
  case ${option} in
    h) usage; exit 1;;
    d) deployId=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${deployId}" ]]; then
  echo "No deploy id specified!"
  exit 1
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f ${currentPath}/../env.properties ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "deploy" "server") )

if [[ "${#serverList}" -eq 0 ]]; then
  echo "No servers specified"
  exit 1
fi

for server in "${serverList[@]}"; do
  type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
  linkList=( $(ini-parse "${currentPath}/../env.properties" "no" "${server}" "link") )
  deployPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "deployPath")
  webUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webUser")
  webGroup=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webGroup")

  if [[ "${#linkList}" -gt 0 ]]; then
    if [[ "${type}" == "ssh" ]]; then
      echo "--- @Todo: Creating links on remote server: ${server} ---"
      exit 1
    else
      echo "--- Creating links on local server: ${server} ---"
      link=$(IFS=, ; echo "${linkList[*]}")
      "${currentPath}/link-local.sh" \
        -l "${link}" \
        -p "${deployPath}/${deployId}" \
        -u "${webUser}" \
        -g "${webGroup}"
    fi
  else
    echo "Nothing to link on server: ${server}"
  fi
done
