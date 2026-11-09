#!/bin/bash
# Usage: package.sh <target>, run beside out/. Writes ffmpeg-<target>.tar.gz
# (zip on Windows) and its .sha256, and records each file's size.
set -euo pipefail
name=ffmpeg-$1
source "$(dirname "$0")/../versions.env"
{
  echo "FFmpeg $FFMPEG, GPL, for $1"
  echo "Built by instrument-org/ffmpeg-build from:"
  sed -n '/^[A-Z]/p' "$(dirname "$0")/../versions.env"
} > out/BUILDINFO.txt
cd out
if [[ $1 == win32-* ]]; then
  7z a -bd -tzip "../$name.zip" . >/dev/null
  file=$name.zip
else
  tar -czf "../$name.tar.gz" .
  file=$name.tar.gz
fi
cd ..
if command -v sha256sum >/dev/null; then sha256sum "$file" > "$file.sha256"; else shasum -a 256 "$file" > "$file.sha256"; fi
du -k out/bin/* out/lib/* "$file" 2>/dev/null | tee -a timings.txt
