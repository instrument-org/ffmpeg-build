# ffmpeg-build

Our builds of [FFmpeg](https://ffmpeg.org) for Instrument, which runs `ffmpeg` and `ffprobe` for the agent's media commands and for every image and video it reads. Each release has one archive per platform Instrument ships (macOS arm64 and x64, Windows x64 and arm64, Linux x64 and arm64), with a checksum beside each and a `SHA256SUMS` file covering all of them. Instrument downloads a release at build time and checks it against pinned SHA-256 sums.

The builds are GPL (`--enable-gpl --enable-version3`, so GPLv3) with every codec library that license allows, x264 and x265 included, and nothing from `--enable-nonfree`, which could not be redistributed. The smoke test fails a build that has it.

Each archive holds `bin/ffmpeg` and `bin/ffprobe`, `licenses/COPYING.GPLv3`, and `BUILDINFO.txt` naming what it was built from.

- **Linux and Windows** come from [BtbN/FFmpeg-Builds](https://github.com/BtbN/FFmpeg-Builds)' `gpl-shared` variant: the two programs share FFmpeg's libraries, beside them in `bin/` on Windows and in `lib/` on Linux (found through an `$ORIGIN/../lib` rpath). BtbN cross-compiles in Docker images that carry every dependency already built; `versions.env` pins the script's commit and each image's digest.
- **macOS** comes from [markus-perl/ffmpeg-build-script](https://github.com/markus-perl/ffmpeg-build-script), which builds every library from a tarball pinned by SHA-256 and links them statically, for macOS 11 and newer. The workflow checks that each binary links nothing outside the system.

## Source

The source for a release is FFmpeg at the version in `versions.env`: its release tarball on macOS, and on Linux and Windows its release branch at `FFMPEG_COMMIT`, which is that release plus the fixes FFmpeg has put on the branch since. BtbN's images carry codec libraries newer than the release tag compiles against, and BtbN builds that branch too. The codec libraries are the versions pinned by the build script and images `versions.env` names at that tag.

## Versions

`versions.env` names the FFmpeg release, the BtbN commit and image digests, and the macOS build script's commit. To move to a new FFmpeg release, change `FFMPEG`; for a new major or minor version, take a BtbN commit that has its addin and the digests of its `gpl-shared-<major.minor>` images. Push, and check that every build and smoke test passes.

## Patches we carry

| Patch | What it does | Drop it when |
| --- | --- | --- |
| `patches/ffmpeg-builds/0001-checkout-a-pinned-commit.patch` | Checks out `FFMPEG_COMMIT` after cloning the release branch, which BtbN builds at its head | BtbN's build takes a commit |
| `patches/ffmpeg-build-script/0001-gpl-without-nonfree.patch` | The script's one switch for GPL codecs also turns on `--enable-nonfree` and fdk-aac; this keeps the GPL half only | the script gets a GPL-only switch |

## Releasing

Every push builds and smoke-tests all six platforms. Pushing a tag (`git tag 2026.11.09 && git push --tags`) also publishes the archives as a GitHub release. macOS and Windows signing happens later, when Instrument packages the app.
