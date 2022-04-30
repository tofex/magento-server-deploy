#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -v  Deploy version
  -d  Deploy Id (used as directory name)

Example: ${scriptName} -v 1.0.0 -d 12345
EOF
}

trim()
{
  echo -n "$1" | xargs
}

version=
deployId=

while getopts hv:d:? option; do
  case ${option} in
    h) usage; exit 1;;
    v) version=$(trim "$OPTARG");;
    d) deployId=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${version}" ]]; then
  echo "No version specified!"
  exit 1
fi

if [[ -z "${deployId}" ]]; then
  echo "No deploy id specified!"
  exit 1
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

buildServer=$(ini-parse "${currentPath}/../env.properties" "yes" "build" "server")
buildServerType=$(ini-parse "${currentPath}/../env.properties" "yes" "${buildServer}" "type")

versionPathName=$(echo "${version}" | sed 's/[^a-zA-Z0-9\.\-]/_/g')

if [[ "${buildServerType}" == "ssh" ]]; then
  echo "Todo: Using build from remote server: ${buildServer}"
  exit 1
else
  echo "Using build from local server: ${buildServer}"

  buildPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${buildServer}" "buildPath")
  versionFile="${buildPath}/${versionPathName}.tar.gz"
  if [[ ! -f "${versionFile}" ]]; then
    echo "Missing version file: ${versionFile}"
    exit 1
  fi
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "deploy" "server") )

if [[ "${#serverList}" -eq 0 ]]; then
  echo "No servers specified"
  exit 1
fi

for server in "${serverList[@]}"; do
  type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
  deployPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "deployPath")
  webUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webUser")
  webGroup=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webGroup")
  if [[ "${type}" == "ssh" ]]; then
    echo "--- @Todo: Extracting build on remote server: ${server} ---"
    exit 1
  else
    echo "--- Extracting build on local server: ${server} ---"
    "${currentPath}/build-local.sh" \
      -a "${versionFile}" \
      -p "${deployPath}/${deployId}" \
      -u "${webUser}" \
      -g "${webGroup}"
  fi
done
