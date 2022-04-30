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

while getopts hd:? option; do
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
  deployPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "deployPath")
  webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
  webUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webUser")
  webGroup=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webGroup")
  if [[ "${type}" == "ssh" ]]; then
    echo "--- Todo: Switching on remote server: ${server} ---"
    exit 1
  else
    echo "--- Switching on local server: ${server} ---"
    "${currentPath}/switch-local.sh" \
      -p "${deployPath}/${deployId}" \
      -w "${webPath}" \
      -u "${webUser}" \
      -g "${webGroup}"
  fi
done
