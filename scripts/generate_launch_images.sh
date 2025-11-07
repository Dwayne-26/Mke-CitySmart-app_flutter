#!/usr/bin/env bash
set -euo pipefail
ASSET_DIR="ios/Runner/Assets.xcassets/LaunchImage.imageset"
BASE=1024
for SCALE in 1 2 3; do
  SIZE=$((BASE * SCALE))
  CX=$((SIZE / 2))
  CY=$CX
  RADIUS=$((SIZE * 2 / 5))
  INNER=$((RADIUS * 7 / 10))
  ARC=$((RADIUS + SIZE / 18))
  STROKE=$((SIZE / 80))
  OUTFILE="$ASSET_DIR/LaunchImage$([[ $SCALE -eq 1 ]] && echo '' || echo "@${SCALE}x").png"
  magick -size ${SIZE}x${SIZE} xc:'#003522' \
    -fill '#0F5D3C' -draw "circle ${CX},${CY} ${CX},$((CY - RADIUS))" \
    -fill '#003522' -draw "circle ${CX},${CY} ${CX},$((CY - INNER))" \
    -stroke '#BFF7DD' -strokewidth ${STROKE} -fill none \
    -draw "arc $((CX - ARC)),$((CY - ARC)) $((CX + ARC)),$((CY + ARC)) -60,160" \
    -font 'Helvetica-Bold' -fill '#FFFFFF' -pointsize $((360 * SCALE / 3)) -gravity center \
    -annotate +0+0 'P' \
    "$OUTFILE"
  echo "Generated $OUTFILE"
done
