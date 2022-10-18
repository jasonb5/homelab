#!/bin/bash

function assert_not_empty() {
  if [[ -z "${!1}" ]]; then
    echo "${1} is not defined"
    exit 1
  fi
}

function assert_exists() {
  if [[ ! -e "${!1}" ]]; then
    echo "${!1} does not exist"
    exit 1
  fi
}

function assert_value_in() {
  local var="${1}" && shift
  local value="${!var}"

  assert_not_empty "${var}"

  for item in "${@}"; do
    [[ "${item}" == "${value}" ]] && return
  done

  echo "\"${value}\" is not valid, possible choices \"$(echo ${@} | tr -s ' ' ',\ ')\""

  exit 1
}

function debug() {
  [[ "${DEBUG}" == "true" ]] && echo "${@}"
}

[[ "${DEBUG}" == "true" ]] && set -x

assert_not_empty INSTALLER_PATH
assert_value_in INSTALLER_TYPE curse
assert_not_empty INSTALL_PATH

DEFAULT_JRE_URL="https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u345-b01/OpenJDK8U-jre_x64_linux_hotspot_8u345b01.tar.gz"
INSTANCE_PATH="${INSTALL_PATH}/instance"
DOWNLOAD_PATH="${INSTALL_PATH}/downloads"
JRE_PATH="${INSTALL_PATH}/jre"
JRE_URL="${JRE_URL:-${DEFAULT_JRE_URL}}"

debug "INSTALLER_PATH = ${INSTALLER_PATH}"
debug "INSTALLER_TYPE = ${INSTALLER_TYPE}"
debug "INSTALL_PATH = ${INSTALL_PATH}"
debug "INSTANCE_PATH = ${INSTANCE_PATH}"
debug "DOWNLOAD_PATH = ${DOWNLOAD_PATH}"
debug "JRE_PATH = ${JRE_PATH}"
debug "JRE_URL = ${JRE_URL}"

function create_dir() {
  local path="${1}"

  if [[ ! -e "${path}" ]]; then
    echo "Creating directory \"${path}\""

    mkdir -p "${path}"
  fi
}

function copy() {
  local src="${1}"
  local filename="$(basename ${src})"
  local dst="${2}"

  create_dir "${dst}"

  if [[ ! -e "${dst}/${filename}" ]]; then
    echo "Copying \"${src}\" -> \"${dst}\""

    cp "${src}" "${dst}"
  fi
}

function download() {
  local url="${1}"
  local filename="$(basename ${url})"
  local dst="${2}"

  create_dir "${dst}"

  if [[ ! -e "${dst}/${filename}" ]]; then
    echo "Downloading \"${url}\" -> \"${dst}\""

    curl -sSfL -o "${dst}/${filename}" "${url}"
  fi
}

function install_jre() {
  local filename="$(basename ${1})"

  download "${1}" "${DOWNLOAD_PATH}"

  create_dir "${2}"

  if [[ ! -e "${2}/bin" ]]; then
    echo "Extracting \"${DOWNLOAD_PATH}/${filename}\" -> \"${2}\""

    tar -xvf "${DOWNLOAD_PATH}/${filename}" -C "${2}" --strip-components=1
  fi

  export PATH="${2}/bin:${PATH}"
}

function extract_curse_modpack() {
  local src="${1}"
  local dst="${2}"

  create_dir "${dst}"

  if [[ ! -e "${dst}/launch.sh" ]]; then
    echo "Extracting \"${src}\" -> \"${dst}\""

    unzip -d "${dst}" "${src}"
  fi
}

function modify_server_property() {
  if [[ -n "${!2}" ]]; then
    echo "Setting \"${1}\" to \"${!2}\""

    sed -i"" "s/${1}.*/${1}=${!2}/" "${INSTANCE_PATH}/server.properties"
  fi
}

function install_modpack() {
  local filename="$(basename ${INSTALLER_PATH})"

  copy "${INSTALLER_PATH}" "${DOWNLOAD_PATH}" 

  if [[ "${INSTALLER_TYPE}" == "curse" ]]; then
    echo "Install curse modpack to ${INSTANCE_PATH}"

    install_jre "${JRE_URL}" "${JRE_PATH}"

    extract_curse_modpack "${DOWNLOAD_PATH}/${filename}" "${INSTANCE_PATH}"

    modify_server_property enable-rcon RCON_ENABLE
    modify_server_property rcon.port RCON_PORT
    modify_server_property rcon.password RCON_PASSWORD
    modify_server_property server-ip SERVER_IP

    pushd "${INSTANCE_PATH}"

    chmod +x launch.sh

    ./launch.sh
  fi
}

install_modpack
