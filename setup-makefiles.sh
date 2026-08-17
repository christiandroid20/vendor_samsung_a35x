#!/bin/bash
#
# Copyright (C) 2024 The Android Open-Source Project
#
# SPDX-License-Identifier: Apache-2.0
#
# Genera Android.mk (PRODUCT_COPY_FILES / módulos prebuilt) y
# a35x-vendor.mk (PRODUCT_PACKAGES) a partir de proprietary-files.txt.
# Se llama automáticamente al final de extract-files.sh.

set -e

DEVICE=a35x
VENDOR=samsung

MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROPRIETARY_FILES="${MY_DIR}/proprietary-files.txt"

ANDROIDMK="${MY_DIR}/Android.mk"
VENDORMK="${MY_DIR}/${DEVICE}-vendor.mk"

cat > "${ANDROIDMK}" << 'HEADER'
# Auto-generado por setup-makefiles.sh -- no editar a mano.
# Vuelve a correr extract-files.sh para regenerarlo.

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),a35x)

HEADER

cat > "${VENDORMK}" << 'HEADER'
# Auto-generado por setup-makefiles.sh -- no editar a mano.
# Vuelve a correr extract-files.sh para regenerarlo.

PRODUCT_SOURCE_FILES := \
HEADER

while IFS= read -r LINE || [ -n "${LINE}" ]; do
    [[ "${LINE}" =~ ^#.*$ ]] && continue
    [ -z "${LINE}" ] && continue
    # Un "-" al inicio = sin regla automática (se maneja a mano en Android.mk)
    [[ "${LINE}" =~ ^- ]] && continue
    FILE=$(echo "${LINE}" | cut -d';' -f1)
    BASENAME=$(basename "${FILE}")
    echo "    vendor/${VENDOR}/${DEVICE}/proprietary/${FILE} \\" >> "${VENDORMK}"
done < "${PROPRIETARY_FILES}"

echo "" >> "${VENDORMK}"
echo "endif # TARGET_DEVICE" >> "${ANDROIDMK}"

echo "Generados: ${ANDROIDMK} y ${VENDORMK}"
