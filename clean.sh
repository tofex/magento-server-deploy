#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f ${currentPath}/../env.properties ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "deploy" "server") )
deployHistoryCount=$(ini-parse "${currentPath}/../env.properties" "no" "deploy" "deployHistoryCount")

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
    echo "--- @Todo: Cleaning on remote server: ${server} ---"
    exit 1
  else
    echo "--- Cleaning on local server: ${server} ---"
    if [[ -n "${deployHistoryCount}" ]]; then
      "${currentPath}/clean-local.sh" \
        -d "${deployPath}" \
        -c "${deployHistoryCount}" \
        -u "${webUser}" \
        -g "${webGroup}"
    else
      "${currentPath}/clean-local.sh" \
        -d "${deployPath}" \
        -u "${webUser}" \
        -g "${webGroup}"
    fi
  fi
done
