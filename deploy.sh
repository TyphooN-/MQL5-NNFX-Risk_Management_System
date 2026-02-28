#!/usr/bin/env bash
set -uo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_EXPERTS="$REPO_DIR/Experts"
SRC_INDICATORS="$REPO_DIR/Indicators"
SRC_INCLUDE="$REPO_DIR/Include"

EXPERT_FILES=(
    "TyphooN.mq5"
    "TyAlgo.mq5"
)

# Verify source directories exist before scanning
for src_dir in "$SRC_EXPERTS" "$SRC_INDICATORS" "$SRC_INCLUDE"; do
    if [ ! -d "$src_dir" ]; then
        echo "ERROR: source directory not found: $src_dir"
        exit 1
    fi
done

# All indicator source files (.mq5, .mq4, .mqh) — recursive, preserving subdirs
# Excludes Retired/ directory (legacy indicators not deployed)
INDICATOR_FILES=()
while IFS= read -r -d '' f; do
    INDICATOR_FILES+=("${f#"$SRC_INDICATORS/"}")
done < <(find "$SRC_INDICATORS" -path "$SRC_INDICATORS/Retired" -prune -o -type f \( -name '*.mqh' -o -name '*.mq5' -o -name '*.mq4' \) -print0)

# Include files with relative paths preserved
INCLUDE_FILES=()
while IFS= read -r -d '' f; do
    INCLUDE_FILES+=("${f#"$SRC_INCLUDE/"}")
done < <(find "$SRC_INCLUDE" -type f \( -name '*.mqh' -o -name '*.mq5' \) -print0)

copied=0
skipped=0
failed=0
total_targets=0

for mt5_dir in /home/typhoon/.mt5_*/; do
    [ -d "$mt5_dir" ] || continue
    MQL5_DIR="$mt5_dir/drive_c/Program Files/Darwinex MetaTrader 5/MQL5"
    if [ ! -d "$MQL5_DIR" ]; then
        echo "SKIP  $(basename "$mt5_dir"): MQL5 directory not found"
        skipped=$((skipped + 1))
        continue
    fi
    total_targets=$((total_targets + 1))
    DST_EXPERTS="$MQL5_DIR/Experts"
    DST_INDICATORS="$MQL5_DIR/Indicators"
    DST_INCLUDE="$MQL5_DIR/Include"
    inst="$(basename "$mt5_dir")"
    inst_failed=0

    for f in "${EXPERT_FILES[@]}"; do
        src="$SRC_EXPERTS/$f"
        dst="$DST_EXPERTS/$f"
        if [ ! -f "$src" ]; then
            echo "FAIL  $inst: source $f not found"
            failed=$((failed + 1))
            inst_failed=$((inst_failed + 1))
            continue
        fi
        if cmp -s "$src" "$dst" 2>/dev/null; then
            continue
        fi
        if cp "$src" "$dst"; then
            copied=$((copied + 1))
        else
            echo "FAIL  $inst: could not copy $f"
            failed=$((failed + 1))
            inst_failed=$((inst_failed + 1))
        fi
    done

    for f in "${INDICATOR_FILES[@]}"; do
        src="$SRC_INDICATORS/$f"
        dst="$DST_INDICATORS/$f"
        if [ ! -f "$src" ]; then
            echo "FAIL  $inst: source Indicators/$f not found"
            failed=$((failed + 1))
            inst_failed=$((inst_failed + 1))
            continue
        fi
        dst_dir="$(dirname "$dst")"
        [ -d "$dst_dir" ] || mkdir -p "$dst_dir"
        if cmp -s "$src" "$dst" 2>/dev/null; then
            continue
        fi
        if cp "$src" "$dst"; then
            copied=$((copied + 1))
        else
            echo "FAIL  $inst: could not copy Indicators/$f"
            failed=$((failed + 1))
            inst_failed=$((inst_failed + 1))
        fi
    done

    for f in "${INCLUDE_FILES[@]}"; do
        src="$SRC_INCLUDE/$f"
        dst="$DST_INCLUDE/$f"
        if [ ! -f "$src" ]; then
            echo "FAIL  $inst: source Include/$f not found"
            failed=$((failed + 1))
            inst_failed=$((inst_failed + 1))
            continue
        fi
        dst_dir="$(dirname "$dst")"
        [ -d "$dst_dir" ] || mkdir -p "$dst_dir"
        if cmp -s "$src" "$dst" 2>/dev/null; then
            continue
        fi
        if cp "$src" "$dst"; then
            copied=$((copied + 1))
        else
            echo "FAIL  $inst: could not copy Include/$f"
            failed=$((failed + 1))
            inst_failed=$((inst_failed + 1))
        fi
    done

    if [ "$inst_failed" -gt 0 ]; then
        echo " WARN  $inst ($inst_failed failures)"
    else
        echo "  OK  $inst"
    fi
done

echo ""
echo "Deploy complete: $total_targets installations, $copied files copied, $skipped skipped, $failed failed"
