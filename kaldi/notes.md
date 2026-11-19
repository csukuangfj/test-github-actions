# What's inside the Kaldi Docker image

Notes describing the contents of the container image built by this repo.

- **Image:** `ghcr.io/csukuangfj/kaldi` (tags: `latest`, `2026-11-19`)
- **Built from:** [`kaldi/Dockerfile`](./Dockerfile), which is `FROM kaldiasr/kaldi:latest`
  (the official CPU image, built upstream from Kaldi's `docker/debian12-cpu`).
- **How this inventory was captured:** the [`test-kaldi`](../.github/workflows/test-kaldi.yaml)
  workflow runs the image and dumps every binary / library / header it ships, plus the
  Kaldi git commit and a `--help` smoke run. Measured in GitHub Actions run `44498496120`,
  job `135471748056`, on **2026-11-19**.
- **Cross-reference:** the same source tree is checked out at `../kaldi`; the image is
  essentially that tree built on Linux (locally it is a macOS build with `.dylib`,
  in Docker a Linux build with `.so`).

## Base system

| Item | Value |
|------|-------|
| Base OS | Debian 12 (from `kaldiasr/kaldi` CPU image) |
| Arch | linux/amd64 (x86-64) |
| Kaldi location | `/opt/kaldi` (git checkout of `kaldi-asr/kaldi` @ `f400766`, 2025-07-22) |
| Build config | `./configure --shared --mathlib=OPENBLAS` → shared libs + OpenBLAS |
| Working dir | `/opt/kaldi` |

`/opt/kaldi` top level: `cmake/`, `docker/`, `egs/` (~105 example recipes), `misc/`,
`scripts/`, `src/`, `tools/`, `windows/`, plus `CMakeLists.txt`, `COPYING`, `INSTALL`,
`README.md`.

## Kaldi source commit (what the image was built from)

`/opt/kaldi` is a git checkout of [kaldi-asr/kaldi](https://github.com/kaldi-asr/kaldi).
Its latest commit — i.e. the exact Kaldi version baked into the image:

| Field | Value |
|-------|-------|
| Commit | `f4007661023b98b8081fd875029f0dee62242fd1` (short `f400766`) |
| Branch | `master` |
| Author | Daniel Povey |
| Date | 2025-07-22 |
| Subject | Merge PR #4974 — *Updated Phonetisaurus install script to a working repository* |
| Remote | `https://github.com/kaldi-asr/kaldi.git` |

## Binaries — ~480 Kaldi command-line tools

Kaldi's compiled programs live in `src/<module>bin/`. Each directory also contains the
`.cc` source and `.o` object next to the built executable. The `*bin` directories
present and their executable counts:

| Directory | Executables | Representative tools |
|-----------|-------------|----------------------|
| `src/bin` | 75 | `acc-lda`, `acc-tree-stats`, `ali-to-phones`, `align-mapped`, `build-tree`, `copy-*` |
| `src/gmmbin` | 73 | `gmm-*` (training / decoding for GMM systems) |
| `src/latbin` | 59 | `lattice-*` (lattice generation, rescoring, best path) |
| `src/nnet2bin` | 50 | `nnet-*` (nnet2 / older neural nets) |
| `src/featbin` | 48 | `compute-mfcc-feats`, `copy-feats`, `compute-fbank-feats`, `compute-spectrogram-feats` |
| `src/nnet3bin` | 46 | `nnet3-*` (nnet3 / x-vector / chain models) |
| `src/ivectorbin` | 27 | `ivector-*` (i-vectors, PLDA) |
| `src/fstbin` | 21 | Kaldi FST utilities |
| `src/chainbin` | 19 | `chain-*` (chain training) |
| `src/nnetbin` | 19 | `nnet-*` (nnet1) |
| `src/online2bin` | 15 | `online2-*`, online/streaming decoding |
| `src/fgmmbin` | 12 | `fgmm-*` (full-covariance GMM) |
| `src/kwsbin` | 7 | keyword search |
| `src/rnnlmbin` | 6 | `rnnlm-*` |
| `src/lmbin` | 2 | `arpa-to-const-arpa` |
| `src/onlinebin` | 1 | `java-online-audio-client` |
| **Total** | **~480** | |

Also present but **not compiled** in this CPU image (sources only, no executable):

- `src/sgmm2bin` — 22 `.cc` sources (SGMM2 tools, not built)
- `src/tfrnnlmbin` — 2 `.cc` sources (`lattice-lmrescore-tf-rnnlm*.cc`; needs TensorFlow)
- `src/cudadecoderbin`, `src/cudafeatbin` — CUDA tools, sources only (expected in a CPU image)

## Libraries

**Kaldi shared libraries** — 21 `libkaldi-*.so` (symlinked in `src/lib/`, real files in
each `src/<module>/`):

```
libkaldi-base      libkaldi-chain    libkaldi-cudamatrix  libkaldi-decoder
libkaldi-feat      libkaldi-fstext   libkaldi-gmm         libkaldi-hmm
libkaldi-ivector   libkaldi-kws      libkaldi-lat         libkaldi-lm
libkaldi-matrix    libkaldi-nnet     libkaldi-nnet2       libkaldi-nnet3
libkaldi-online2   libkaldi-rnnlm    libkaldi-transform   libkaldi-tree
libkaldi-util
```

**OpenFST 1.8.4** (`/opt/kaldi/tools/openfst-1.8.4`, symlinked `tools/openfst`):

- libs: `libfst`, `libfstfar`, `libfstfarscript`, `libfstlookahead`, `libfstngram`
  (each as `.a` and `.so.26.0.0`)

**OpenBLAS 0.3.13** (Zen target) in `/opt/kaldi/tools/OpenBLAS/install/lib`:

- `libopenblas_zen-r0.3.13.a`, `libopenblas_zen-r0.3.13.so`

## openfst command-line tools

46 binaries in `/opt/kaldi/tools/openfst/bin`, e.g. `fstcompile`, `fstinfo`, `fstcompose`,
`fstconvert`, `fstdeterminize`, `fstminimize`, `fstproject`, `fstshortestpath`, `fstprint`,
`fstinfo`, and the `far*` family (`farcompilestrings`, `farcreate`, `farinfo`, …).

## Header files

| Header set | Location | Count |
|------------|----------|-------|
| Kaldi | `/opt/kaldi/src/**/*.h` | **398** |
| openfst | `/opt/kaldi/tools/openfst/include/**/*.h` | **187** |

(Kaldi headers live alongside their modules — `src/base/*.h`, `src/matrix/*.h`,
`src/nnet3/*.h`, etc. — there is no single `include/` dir.)

## Toolchain / PATH

The upstream image leaves Kaldi's binaries **off** `PATH`. This repo's `Dockerfile` wrapper
prepends them so tools run by name:

- Kaldi: `/opt/kaldi/src/{bin,featbin,fstbin,gmmbin,latbin,ivectorbin,nnetbin,nnet2bin,nnet3bin,online2bin,lmbin,rnnlmbin}`
- openfst: `/opt/kaldi/tools/openfst/bin`

Verified on `PATH`: `compute-mfcc-feats` → `src/featbin/`, `copy-feats` → `src/featbin/`,
`fstcompile` → `tools/openfst/bin/`.

## Smoke test — tools actually run

Beyond existing on `PATH`, the test invokes each tool with `--help` to prove the binaries
execute (dynamic linking + openfst OK), not just exist. Usage printed correctly for all:

| Tool | Module | Usage synopsis |
|------|--------|----------------|
| `compute-mfcc-feats` | featbin | `compute-mfcc-feats [options] <wav-rspecifier> <feats-wspecifier>` |
| `copy-feats` | featbin | `copy-feats [options] <feature-rspecifier> <feature-wspecifier>` |
| `gmm-info` | gmmbin | `gmm-info [options] <model-in>` |
| `lattice-best-path` | latbin | `lattice-best-path [options] <lattice-rspecifier> [...]` |
| `nnet3-info` | nnet3bin | `nnet3-info [options] <raw-nnet>` |
| `ivector-compute-plda` | ivectorbin | `ivector-compute-plda [options] <spk2utt> <ivector> <plda-out>` |
| `align-text` | bin | `align-text [options] <text1> <text2> <alignment>` |
| `fstcompile` | openfst | `fstcompile [text.fst [binary.fst]]` |

## Sanity status (from the test run)

```
OK      compute-mfcc-feats -> /opt/kaldi/src/featbin/compute-mfcc-feats
OK      copy-feats         -> /opt/kaldi/src/featbin/copy-feats
OK      fstcompile         -> /opt/kaldi/tools/openfst/bin/fstcompile
OK      kaldi binaries present
OK      shared libraries present
INVENTORY COMPLETE — all checks passed
```

## Quick use

```bash
docker run --rm -it ghcr.io/csukuangfj/kaldi:latest bash
# pwd -> /opt/kaldi ; Kaldi/openfst tools are on the PATH
```
