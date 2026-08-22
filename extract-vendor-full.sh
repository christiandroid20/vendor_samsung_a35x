#!/bin/bash
#
# Copyright (C) 2024 The Android Open-Source Project
#
# SPDX-License-Identifier: Apache-2.0
#
# Copia la partición vendor/ COMPLETA desde una fuente ya extraída
# (un dump de firmware, o cualquier carpeta que tenga una subcarpeta
# vendor/ con la estructura real del equipo) y genera
# proprietary-files.txt automáticamente a partir de lo que en verdad
# se copió -- a diferencia de extract-files.sh (que sigue una lista
# curada a mano), este modo no da por hecho de antemano qué existe.
#
# En un equipo con Treble, todo lo que vive en vendor/ es por
# definición específico del fabricante -- por eso tiene sentido
# copiarlo completo en vez de listarlo archivo por archivo.
#
# Uso:
#   ./extract-vendor-full.sh /ruta/a/dump   (debe contener dump/vendor/...)

set -e

DEVICE=a35x
VENDOR=samsung

MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDIR="${MY_DIR}/proprietary"
SRC="$1"

if [ -z "${SRC}" ] || [ ! -d "${SRC}/vendor" ]; then
    echo "Uso: ./extract-vendor-full.sh /ruta/a/dump"
    echo "  (la ruta debe contener una carpeta vendor/ -- ej: un dump de firmware ya extraído)"
    exit 1
fi

echo "Copiando vendor/ completo desde ${SRC}..."
rm -rf "${OUTDIR}/vendor"
mkdir -p "${OUTDIR}"
cp -a "${SRC}/vendor" "${OUTDIR}/vendor"

TOTAL=$(find "${OUTDIR}/vendor" -type f | wc -l)
echo "Copiados ${TOTAL} archivos."

echo "Generando proprietary-files.txt a partir de lo copiado..."
{
    echo "# Generado automáticamente por extract-vendor-full.sh"
    echo "# a partir de una copia completa de vendor/ -- $(date -u +%Y-%m-%d)"
    echo "# Fuente: ${SRC}"
    echo "#"
    cd "${OUTDIR}"
    find vendor -type f | sort
} > "${MY_DIR}/proprietary-files.txt"

"${MY_DIR}/setup-makefiles.sh"

echo ""
echo "Listo: ${TOTAL} archivos en proprietary/vendor/, proprietary-files.txt regenerado."
