# A thin wrapper around the official Kaldi image.
#
#   https://hub.docker.com/r/kaldiasr/kaldi
#
# The upstream CPU image (built from kaldi's docker/debian12-cpu) installs Kaldi
# to /opt/kaldi but leaves its binaries OFF the PATH and ships no entrypoint.
# This wrapper:
#   * puts the Kaldi program dirs + openfst on the PATH so tools like
#     compute-mfcc-feats / copy-feats / fstcompile are directly runnable
#   * pins a predictable WORKDIR and a plain bash CMD
#   * normalizes the entrypoint so `docker run <img> <cmd>` behaves the same
#     regardless of what the upstream base happened to ship
FROM kaldiasr/kaldi:latest

LABEL org.opencontainers.image.title="kaldi (wrapper)"
LABEL org.opencontainers.image.description="kaldiasr/kaldi with Kaldi/openfst on PATH"
LABEL org.opencontainers.image.source="https://github.com/csukuangfj/test-github-actions"

# Kaldi is installed here by the upstream image.
ENV KALDI_ROOT=/opt/kaldi

# Prepend the Kaldi program dirs and openfst to the PATH. Any directory that the
# upstream build did not create is harmless to list. The system dirs are kept at
# the end so nothing from the Debian base is lost.
ENV PATH=/opt/kaldi/src/bin:/opt/kaldi/src/featbin:/opt/kaldi/src/fstbin:/opt/kaldi/src/gmmbin:/opt/kaldi/src/latbin:/opt/kaldi/src/ivectorbin:/opt/kaldi/src/nnetbin:/opt/kaldi/src/nnet2bin:/opt/kaldi/src/nnet3bin:/opt/kaldi/src/online2bin:/opt/kaldi/src/lmbin:/opt/kaldi/src/rnnlmbin:/opt/kaldi/tools/openfst/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /opt/kaldi

# Normalize how the container is invoked. Clearing ENTRYPOINT guarantees that
# `docker run <img> <cmd>` runs <cmd> directly (no upstream entrypoint to fight),
# and a bash CMD keeps plain `docker run -it <img>` interactive.
ENTRYPOINT []
CMD ["/bin/bash"]
