#!/bin/bash
#
# Copyright (C) 2024 The Android Open-Source Project
#
# SPDX-License-Identifier: Apache-2.0
#
# Extrae los blobs propietarios listados en proprietary-files.txt desde
# el equipo real (via ADB) o desde un dump de firmware ya extraído.
#
# Uso:
#   ./extract-files.sh              # via ADB (equipo conectado y rooteado/con acceso adb root)
#   ./extract-files.sh /ruta/dump   # desde una carpeta con un dump de firmware ya extraído

set -e

DEVICE=a35x
VENDOR=samsung

MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANDROID_ROOT="${MY_DIR}/../../.."
BASE_DIR="vendor/${VENDOR}/${DEVICE}/proprietary"
OUTDIR="${ANDROID_ROOT}/${BASE_DIR}"

if [ -z "$1" ]; then
    SRC=adb
else
    SRC="$1"
fi

function init_adb_connection() {
    adb start-server
    echo "Esperando el equipo (necesita adb root)..."
    adb wait-for-device root 2>/dev/null || true
    sleep 3
    adb wait-for-device 2>/dev/null
}

function pull_file() {
    local file="$1"
    local dest="${OUTDIR}/$(dirname "${file}" | sed 's|^/||')"
    mkdir -p "${dest}"
    if [ "${SRC}" = "adb" ]; then
        adb pull "${file}" "${dest}/" 2>/dev/null
    else
        cp "${SRC}/${file}" "${dest}/" 2>/dev/null
    fi
}

if [ "${SRC}" = "adb" ]; then
    init_adb_connection
fi

mkdir -p "${OUTDIR}"

FAILED=()
while IFS= read -r LINE || [ -n "${LINE}" ]; do
    [[ "${LINE}" =~ ^#.*$ ]] && continue
    [ -z "${LINE}" ] && continue
    FILE=$(echo "${LINE}" | cut -d';' -f1 | sed 's/^-//')
    echo "Extrayendo ${FILE}"
    if ! pull_file "/${FILE}"; then
        FAILED+=("${FILE}")
    fi
done < "${MY_DIR}/proprietary-files.txt"

if [ "${#FAILED[@]}" -gt 0 ]; then
    echo ""
    echo "No se pudieron extraer (revisar rutas, puede que no existan en este equipo/firmware):"
    printf '  %s\n' "${FAILED[@]}"
fi

"${MY_DIR}/setup-makefiles.sh"
