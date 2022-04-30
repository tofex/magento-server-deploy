#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

while getopts h? option; do
  case ${option} in
    h) usage; exit 1;;
    ?) usage; exit 1;;
  esac
done

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
  generateAfter=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "generateAfter")
  webUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webUser")
  webGroup=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webGroup")

  if [[ -n "${generateAfter}" ]]; then
    if [[ "${type}" == "ssh" ]]; then
      echo "--- @Todo: Executing generate after on remote server: ${server} ---"
      exit 1
    else
      echo "--- Executing generate after on local server: ${server} ---"
      "${currentPath}/script-local.sh" \
        -s "${generateAfter}" \
        -u "${webUser}" \
        -g "${webGroup}"
    fi
  else
    echo "No generate after to execute on server: ${server}"
  fi
done
