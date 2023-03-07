#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -v  Deploy version
  -n  PHP executable, default: php
  -m  Memory limit (optional)
  -p  Log path
  -f  Log file name

Example: ${scriptName} -s server1 -v 1.0.0 -p /var/www/magento/log/deployments
EOF
}

trim()
{
  echo -n "$1" | xargs
}

version=
phpExecutable=
memoryLimit=
logPath=
logFileName=

while getopts hv:n:m:p:f:? option; do
  case "${option}" in
    h) usage; exit 1;;
    v) version=$(trim "$OPTARG");;
    n) phpExecutable=$(trim "$OPTARG");;
    m) memoryLimit=$(trim "$OPTARG");;
    p) logPath=$(trim "$OPTARG");;
    f) logFileName=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${logPath}" ]]; then
  # shellcheck disable=SC1090
  source "${currentPath}/log.sh" "-" "-"
else
  if [[ -z "${logFileName}" ]]; then
    # shellcheck disable=SC1090
    source "${currentPath}/log.sh" "${logPath}" "-"
  else
    # shellcheck disable=SC1090
    source "${currentPath}/log.sh" "${logPath}" "${logFileName}"
  fi
fi

if [[ -z "${version}" ]]; then
  echo "No version specified"
  exit 1
fi

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

deployId=$(date +"%Y_%m_%d_%H_%M_%S")

"${currentPath}/script-before.sh"

"${currentPath}/build.sh" \
  -v "${version}" \
  -d "${deployId}"

"${currentPath}/link.sh" \
  -d "${deployId}"

"${currentPath}/../ops/maintenance-start.sh"

"${currentPath}/switch.sh" \
  -d "${deployId}"

"${currentPath}/../ops/cache-clean.sh"

if [[ -n "${phpExecutable}" ]]; then
  "${currentPath}/prepare.sh" \
    -d "${deployId}" \
    -e "${phpExecutable}"
else
  "${currentPath}/prepare.sh" \
    -d "${deployId}"
fi

"${currentPath}/generate-before.sh"

if [[ -n "${phpExecutable}" ]]; then
  if [[ -n "${memoryLimit}" ]]; then
    "${currentPath}/../ops/database-upgrade.sh" \
      -b "${phpExecutable}" \
      -i "${memoryLimit}"
  else
    "${currentPath}/../ops/database-upgrade.sh" \
      -b "${phpExecutable}"
  fi
else
  if [[ -n "${memoryLimit}" ]]; then
    "${currentPath}/../ops/database-upgrade.sh" \
      -i "${memoryLimit}"
  else
    "${currentPath}/../ops/database-upgrade.sh"
  fi
fi

"${currentPath}/../ops/cache-clean.sh"

if [[ -n "${phpExecutable}" ]]; then
  if [[ -n "${memoryLimit}" ]]; then
    "${currentPath}/../ops/generate.sh" \
      -b "${phpExecutable}" \
      -m "${memoryLimit}"
  else
    "${currentPath}/../ops/generate.sh" \
      -b "${phpExecutable}"
  fi
else
  if [[ -n "${memoryLimit}" ]]; then
    "${currentPath}/../ops/generate.sh" \
      -m "${memoryLimit}"
  else
    "${currentPath}/../ops/generate.sh"
  fi
fi

"${currentPath}/generate-after.sh"

"${currentPath}/../ops/cache-clean.sh"

"${currentPath}/../ops/fpc-clean.sh"

"${currentPath}/../ops/maintenance-end.sh"

"${currentPath}/deploy-date.sh" \
  -d "$(LC_ALL=en_US.utf8 date +"%Y-%m-%d %H:%M:%S %z")"

"${currentPath}/script-after.sh"

"${currentPath}/clean.sh"

echo "Finished"
