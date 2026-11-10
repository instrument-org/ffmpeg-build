#!/bin/bash
# Usage: smoke-test.sh <unpacked archive dir> <ffmpeg version> <target>
# Runs the binaries the way Instrument does: from where they were unpacked,
# with nothing on PATH or LD_LIBRARY_PATH pointing at them.
set -euo pipefail
dir=$1 version=$2 target=$3
exe=""; [[ -f "$dir/bin/ffmpeg.exe" ]] && exe=.exe
ffmpeg="$dir/bin/ffmpeg$exe" ffprobe="$dir/bin/ffprobe$exe"
unset LD_LIBRARY_PATH DYLD_LIBRARY_PATH

"$ffmpeg" -hide_banner -version | head -1
"$ffprobe" -hide_banner -version | head -1
"$ffmpeg" -hide_banner -version | head -1 | grep -q "version n\?$version" ||
  { echo "expected ffmpeg $version"; exit 1; }

conf=$("$ffmpeg" -hide_banner -buildconf)
for want in --enable-gpl --enable-libx264 --enable-libx265 --enable-libdav1d \
  --enable-libwebp --enable-libvpx --enable-libopus --enable-libmp3lame \
  --enable-libass --enable-libzimg; do
  # BtbN's Windows arm64 images build no libvpx (nor libaom, which dav1d and
  # SVT-AV1 cover); FFmpeg still decodes VP8 and VP9 itself.
  if [[ $target == win32-arm64 && $want == --enable-libvpx ]]; then continue; fi
  grep -q -- "$want" <<<"$conf" || { echo "missing $want"; exit 1; }
done
if grep -q -- --enable-nonfree <<<"$conf"; then
  echo "built with --enable-nonfree, which cannot be redistributed"; exit 1
fi
"$ffmpeg" -hide_banner -h demuxer=mov | grep -q heic || { echo "mov demuxer lacks heic"; exit 1; }

t=$(mktemp -d)
"$ffmpeg" -hide_banner -loglevel error -f lavfi -i testsrc2=size=640x360:rate=30 \
  -f lavfi -i sine=frequency=440 -t 2 -c:v libx264 -c:a aac -pix_fmt yuv420p "$t/h264.mp4"
"$ffmpeg" -hide_banner -loglevel error -i "$t/h264.mp4" -c:v libx265 -tag:v hvc1 -an "$t/hevc.mp4"
"$ffmpeg" -hide_banner -loglevel error -i "$t/h264.mp4" -frames:v 1 "$t/frame.png"
"$ffmpeg" -hide_banner -loglevel error -i "$t/frame.png" "$t/frame.webp"
"$ffmpeg" -hide_banner -loglevel error -i "$t/frame.png" -vf scale=320:-1 "$t/frame.jpg"
"$ffprobe" -v error -show_entries stream=codec_name -of csv=p=0 "$t/h264.mp4" | tr '\n' ' '; echo
"$ffprobe" -v error -show_entries stream=codec_name -of csv=p=0 "$t/hevc.mp4"
"$ffprobe" -v error -show_entries stream=codec_name -of csv=p=0 "$t/frame.webp"
ls -la "$t"
rm -rf "$t"
echo "smoke test passed"
