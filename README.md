# ffmpeg-build

Our builds of [FFmpeg](https://ffmpeg.org) for Instrument, which runs `ffmpeg` and `ffprobe` for the agent's media commands and for every image and video it reads. Each release has one archive per platform Instrument ships (macOS arm64 and x64, Windows x64 and arm64, Linux x64 and arm64), with a checksum beside each and a `SHA256SUMS` file covering all of them. Instrument downloads a release at build time and checks it against pinned SHA-256 sums.

The builds are GPL (`--enable-gpl --enable-version3`, so GPLv3) with every codec library that license allows, x264 and x265 included, and nothing from `--enable-nonfree`, which could not be redistributed. The smoke test fails a build that has it.

A few libraries are left out because another in the build does the same job, so no format is lost: rav1e and libaom (SVT-AV1 encodes AV1, AVIF included, and dav1d decodes it) and Cisco's openh264 (x264 encodes H.264 and FFmpeg decodes it itself). The macOS builds also leave out Vulkan and libplacebo, since a Mac has no Vulkan driver unless MoltenVK is installed; VideoToolbox, Apple's hardware encoder and decoder, stays. `versions.env` lists them (`OMIT_CONFIGURE`, `OMIT_MACOS`), and the smoke test fails a build that has them.

BtbN's Windows arm64 images leave out a few codec libraries the other targets carry: libvpx (FFmpeg still decodes VP8 and VP9 itself), libaom (dav1d decodes AV1 and SVT-AV1 encodes it), libopenmpt, Intel's libvpl, and the AVS2/AVS3 and LCEVC libraries.

Each archive holds `bin/ffmpeg` and `bin/ffprobe`, `licenses/COPYING.GPLv3`, and `BUILDINFO.txt` naming what it was built from.

- **Linux and Windows** come from [BtbN/FFmpeg-Builds](https://github.com/BtbN/FFmpeg-Builds)' `gpl-shared` variant: the two programs share FFmpeg's libraries, beside them in `bin/` on Windows and in `lib/` on Linux (found through an `$ORIGIN/../lib` rpath). BtbN cross-compiles in Docker images that carry every dependency already built; `versions.env` pins the script's commit and each image's digest.
- **macOS** comes from [markus-perl/ffmpeg-build-script](https://github.com/markus-perl/ffmpeg-build-script), which builds every library from a tarball pinned by SHA-256 and links them statically, for macOS 11 and newer. The workflow checks that each binary links nothing outside the system.

## Source

The source for a release is FFmpeg at the version in `versions.env`: its release tarball on macOS, and on Linux and Windows its release branch at `FFMPEG_COMMIT`, which is that release plus the fixes FFmpeg has put on the branch since. BtbN's images carry codec libraries newer than the release tag compiles against, and BtbN builds that branch too. The codec libraries are the versions pinned by the build script and images `versions.env` names at that tag.

Every release attaches that source, as the GPL asks of anyone shipping the binaries: `ffmpeg-source-<commit>.tar.xz` (FFmpeg at `FFMPEG_COMMIT`), `source-linux-windows.tar` (the source of every library BtbN's images compile, fetched by its `download.sh` from the commits its scripts pin, and its scripts with our patches) and `source-macos.tar` (every tarball the macOS build compiles, FFmpeg's release tarball among them, and the build script with our patches). `SOURCE-SHA256SUMS` lists them. The Linux and Windows library source is what BtbN's scripts at `BTBN_COMMIT` pin, which the image digests in `versions.env` were taken beside.

## Versions

`versions.env` names the FFmpeg release, the BtbN commit and image digests, and the macOS build script's commit. To move to a new FFmpeg release, change `FFMPEG`; for a new major or minor version, take a BtbN commit that has its addin and the digests of its `gpl-shared-<major.minor>` images. Push, and check that every build and smoke test passes.

## Patches we carry

| Patch | What it does | Drop it when |
| --- | --- | --- |
| `patches/ffmpeg-builds/0001-checkout-a-pinned-commit.patch` | Checks out `FFMPEG_COMMIT` after cloning the release branch, which BtbN builds at its head | BtbN's build takes a commit |
| `patches/ffmpeg-builds/0002-append-configure-flags.patch` | Appends `FF_CONFIGURE_EXTRA` to FFmpeg's configure line, which the workflow sets to `OMIT_CONFIGURE`; the images bake their own flags in | BtbN's build takes extra configure flags |
| `patches/ffmpeg-build-script/0001-gpl-without-nonfree.patch` | The script's one switch for GPL codecs also turns on `--enable-nonfree` and fdk-aac; this keeps the GPL half only | the script gets a GPL-only switch |

## Releasing

Every push builds and smoke-tests all six platforms. Pushing a tag (`git tag 2026.11.09 && git push --tags`) also publishes the archives as a GitHub release. macOS and Windows signing happens later, when Instrument packages the app.
