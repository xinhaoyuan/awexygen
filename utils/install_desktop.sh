#!/bin/bash

set -euo pipefail

if [[ -z "${AWEXYGEN_DIR:-}" ]]; then
    AWEXYGEN_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
fi

: ${INSTALL_PREFIX:=${XDG_DATA_HOME:-$HOME/.local/share}}

mkdir -p "${INSTALL_PREFIX}/applications"
DESKTOP_PATH="${INSTALL_PREFIX}/applications/awexygen.desktop"

echo "Installing the desktop entry to $DESKTOP_PATH"
(cat <<EOF
[Desktop Entry]
Encoding=UTF-8
Type=Application
Terminal=false
Exec=${AWEXYGEN_DIR}/awexygen
Name=Awexygen
Icon=${AWEXYGEN_DIR}/icon.svg
EOF
) | tee "${INSTALL_PREFIX}/applications/awexygen.desktop"
