#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -d  Deploy date
  -w  Web path
  -u  Web user (optional)
  -g  Web group (optional)

Example: ${scriptName} -d "2021-07-12 03:52:51 +0000" -p /var/www/magento/releases/12345 -w /var/www/magento/htdocs
EOF
}

trim()
{
  echo -n "$1" | xargs
}

deployDate=
webPath=
webUser=
webGroup=

while getopts hd:w:u:g:? option; do
  case ${option} in
    h) usage; exit 1;;
    d) deployDate=$(trim "$OPTARG");;
    w) webPath=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${deployDate}" ]]; then
  echo "No deploy date specified!"
  exit 1
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  exit 1
fi

currentUser=$(whoami)
if [[ -z "${webUser}" ]]; then
  webUser="${currentUser}"
fi

currentGroup=$(id -g -n)
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

cd "${webPath}"

echo "Setting deploy date to: ${deployDate}"
echo "Deploy-Date: ${deployDate}" >> vcs-info.txt
