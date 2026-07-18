#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

WORLDS_DIR="$PROJECT_DIR/worlds"

WORLDS=()
for f in "$WORLDS_DIR"/*.wld; do
    [[ -f "$f" ]] && WORLDS+=("$(basename "$f")")
done

if [[ ${#WORLDS[@]} -eq 0 ]]; then
    echo "No worlds found in $WORLDS_DIR"
    exit 0
fi

echo "========================================="
echo "       Delete Terraria World"
echo "========================================="
echo ""
echo "Available worlds:"
echo ""
for i in "${!WORLDS[@]}"; do
    echo "  $((i + 1))) ${WORLDS[$i]}"
done
echo ""
echo "  0) Cancel"
echo ""

while true; do
    read -rp "Choose [0-${#WORLDS[@]}]: " choice
    if [[ "$choice" == "0" ]]; then
        echo "Aborted."
        exit 0
    fi
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#WORLDS[@]} )); then
        break
    fi
    echo "Invalid choice."
done

SELECTED="${WORLDS[$((choice - 1))]}"
echo ""
read -rp "Delete '${SELECTED}'? [y/N]: " confirm
if [[ "${confirm,,}" != "y" ]]; then
    echo "Aborted."
    exit 0
fi

sudo rm "$WORLDS_DIR/$SELECTED"
echo "Deleted '${SELECTED}'."
