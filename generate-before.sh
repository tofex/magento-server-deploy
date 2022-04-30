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
  generateBefore=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "generateBefore")
  webUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webUser")
  webGroup=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webGroup")

  if [[ -n "${generateBefore}" ]]; then
    if [[ "${type}" == "ssh" ]]; then
      echo "--- @Todo: Executing generate before on remote server: ${server} ---"
      exit 1
    else
      echo "--- Executing generate before on local server: ${server} ---"
      "${currentPath}/script-local.sh" \
        -s "${generateBefore}" \
        -u "${webUser}" \
        -g "${webGroup}"
    fi
  else
    echo "No generate before to execute on server: ${server}"
  fi
done
