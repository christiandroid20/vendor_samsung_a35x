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
#   ./extract-files.sh              # via ADB (equipo conectado)
#   ./extract-files.sh /ruta/dump   # desde una carpeta con un dump de firmware ya extraído
#
# Via ADB, detecta automáticamente cómo tiene acceso root el equipo:
#   1. adb root (adbd corriendo como root) -- el más rápido si funciona
#   2. su vía shell (Magisk/KernelSU) -- funciona aunque adbd no sea root
#   3. sin root -- solo alcanza archivos públicos, como último recurso

set -e

DEVICE=a35x
VENDOR=samsung

MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANDROID_ROOT="${MY_DIR}/../../.."
BASE_DIR="vendor/${VENDOR}/${DEVICE}/proprietary"
# OUTDIR siempre relativo al propio script (MY_DIR), no a una ruta
# derivada de 3 niveles hacia arriba -- eso solo tiene sentido si este
# repo ya esta anidado dentro de un arbol AOSP real en vendor/samsung/a35x,
# y falla (escribe fuera del repo) cuando se corre standalone, como en
# el workflow que genera esto desde un dump de firmware.
OUTDIR="${MY_DIR}/proprietary"

if [ -z "$1" ]; then
    SRC=adb
else
    SRC="$1"
fi

# Modo de acceso detectado: "adbroot", "su", o "none"
ADB_MODE="none"

function init_adb_connection() {
    adb start-server
    echo "Esperando el equipo..."
    adb wait-for-device 2>/dev/null

    # 1) Intentar adb root (adbd como root -- funciona en algunos equipos
    #    rooteados, y en la mayoria de builds custom/eng)
    adb root >/dev/null 2>&1 || true
    sleep 2
    adb wait-for-device 2>/dev/null
    if [ "$(adb shell whoami 2>/dev/null | tr -d '\r')" = "root" ]; then
        ADB_MODE="adbroot"
        echo "Acceso: adbd como root (adb root)"
        return
    fi

    # 2) Fallback: su vía shell (Magisk/KernelSU). Requiere haber
    #    autorizado el acceso root para ADB/Shell en la app de Magisk.
    if adb shell "su -c id" 2>/dev/null | grep -q "uid=0"; then
        ADB_MODE="su"
        echo "Acceso: su vía shell (Magisk/KernelSU)"
        return
    fi

    echo "Aviso: no se detectó acceso root (ni adb root ni su). Solo se van"
    echo "a poder sacar archivos públicos -- revisa el acceso root para ADB"
    echo "en los ajustes de Magisk/KernelSU si esperabas tenerlo."
    ADB_MODE="none"
}

function pull_file() {
    local file="$1"
    local dest="${OUTDIR}/$(dirname "${file}" | sed 's|^/||')"
    local basename_f
    basename_f="$(basename "${file}")"
    mkdir -p "${dest}"

    if [ "${SRC}" != "adb" ]; then
        cp "${SRC}/${file}" "${dest}/" 2>/dev/null
        return $?
    fi

    case "${ADB_MODE}" in
        adbroot)
            adb pull "${file}" "${dest}/" >/dev/null 2>&1
            ;;
        su)
            # Lee el archivo como root via su y lo manda por stdout del
            # shell de adb -- funciona sin que adbd mismo sea root.
            adb shell "su -c 'cat \"${file}\" 2>/dev/null'" > "${dest}/${basename_f}" 2>/dev/null
            # Si quedó vacío (no existía o sin permiso), no cuenta como éxito
            [ -s "${dest}/${basename_f}" ]
            ;;
        *)
            adb pull "${file}" "${dest}/" >/dev/null 2>&1
            ;;
    esac
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
