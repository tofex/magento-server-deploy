#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -d  Deploy date

Example: ${scriptName} -d 12345
EOF
}

trim()
{
  echo -n "$1" | xargs
}

deployDate=

while getopts hd:? option; do
  case ${option} in
    h) usage; exit 1;;
    d) deployDate=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${deployDate}" ]]; then
  echo "No deploy date specified!"
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
  webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
  webUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webUser")
  webGroup=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webGroup")
  if [[ "${type}" == "ssh" ]]; then
    echo "--- @Todo: Setting deploy date on remote server: ${server} ---"
    exit 1
  else
    echo "--- Setting deploy date on local server: ${server} ---"
    "${currentPath}/deploy-date-local.sh" \
      -d "${deployDate}" \
      -w "${webPath}" \
      -u "${webUser}" \
      -g "${webGroup}"
  fi
done
