#!/bin/bash

INSTALLER_PATH="${INSTALLER_PATH}"

INSTALL_PATH="${INSTALL_PATH:-/modpack}"

test -f "${INSTALL_PATH}" || mkdir -p "${INSTALL_PATH}"

unzip -o -d "${INSTALL_PATH}" "${INSTALLER_PATH}"

test -f "${INSTALL_PATH}/launch.sh" && chmod +x "${INSTALL_PATH}/launch.sh"

pushd "${INSTALL_PATH}"

./launch.sh
