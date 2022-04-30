#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -d  Deploy Id (used as directory name)
  -e  PHP executable (optional)

Example: ${scriptName} -d 12345
EOF
}

trim()
{
  echo -n "$1" | xargs
}

deployId=
phpExecutable="php"

while getopts hd:e:? option; do
  case ${option} in
    h) usage; exit 1;;
    d) deployId=$(trim "$OPTARG");;
    e) phpExecutable=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${deployId}" ]]; then
  echo "No deploy id specified!"
  exit 1
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  currentPath="$(dirname "$(readlink -f "$0")")"
fi

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "deploy" "server") )
magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")

if [[ "${#serverList}" -eq 0 ]]; then
  echo "No servers specified"
  exit 1
fi

if [[ "${magentoVersion:0:1}" == 1 ]]; then
  echo "No preparing for Magento 1 required"
  exit 0
fi

for server in "${serverList[@]}"; do
  type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
  deployPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "deployPath")
  webUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webUser")
  webGroup=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webGroup")

  if [[ "${type}" == "ssh" ]]; then
    echo "--- Todo: Preparing on remote server: ${server} ---"
    exit 1
  else
    echo "--- Preparing on local server: ${server} ---"
    "${currentPath}/prepare-local.sh" \
      -p "${deployPath}/${deployId}" \
      -u "${webUser}" \
      -g "${webGroup}" \
      -e "${phpExecutable}"
  fi
done
