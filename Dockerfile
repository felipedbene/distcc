# === Stage 1: Build PowerPC cross-toolchain ===
FROM gentoo/stage3:latest AS builder
LABEL stage="builder"
ENV FEATURES="-pid-sandbox -ipc-sandbox -network-sandbox distcc"
ENV USE="bindist -X cxx"
ENV DISTCC_SAVE_TEMPS=1

# Sync and install build tools
RUN emerge-webrsync && \
    mkdir -p /etc/portage/package.accept_keywords && \
    echo "sys-devel/crossdev" >> /etc/portage/package.accept_keywords/crossdev && \
    emerge --quiet sys-devel/crossdev sys-devel/distcc

# Unmask and install GCC 14.2.1
RUN mkdir -p /etc/portage/package.unmask && \
    echo "=sys-devel/gcc-14.2.1_p20241221 **" >> /etc/portage/package.accept_keywords/gcc && \
    echo "=sys-devel/gcc-14.2.1_p20241221" >> /etc/portage/package.unmask/gcc && \
    emerge --quiet =sys-devel/gcc-14.2.1_p20241221 && \
    gcc-config 1

# Configure overlay for crossdev
RUN mkdir -p /etc/portage/repos.conf /var/db/repos/localrepo/metadata && \
    echo "[localrepo]" > /etc/portage/repos.conf/localrepo.conf && \
    echo "location = /var/db/repos/localrepo" >> /etc/portage/repos.conf/localrepo.conf && \
    echo "masters = gentoo" > /var/db/repos/localrepo/metadata/layout.conf && \
    echo "auto-sync = no" >> /etc/portage/repos.conf/localrepo.conf

# Build PowerPC toolchain
RUN echo "=cross-powerpc-unknown-linux-gnu/gcc-14.2.1_p20241221" >> /etc/portage/package.accept_keywords/cross-powerpc-unknown-linux-gnu && \
    echo "=cross-powerpc-unknown-linux-gnu/gcc-14.2.1_p20241221" >> /etc/portage/package.unmask/cross-powerpc-unknown-linux-gnu && \
    echo "=cross-powerpc-unknown-linux-gnu/binutils-2.41*" >> /etc/portage/package.accept_keywords/cross-powerpc-unknown-linux-gnu && \
    echo "=cross-powerpc-unknown-linux-gnu/linux-headers-6.1*" >> /etc/portage/package.accept_keywords/cross-powerpc-unknown-linux-gnu && \
    echo "=cross-powerpc-unknown-linux-gnu/glibc-2.38*" >> /etc/portage/package.accept_keywords/cross-powerpc-unknown-linux-gnu && \
    crossdev --ov-output /var/db/repos/localrepo --target powerpc-unknown-linux-gnu --gcc 14.2.1_p20241221 > /crossdev-ppc.log || (cat /crossdev-ppc.log && exit 1)

# Symlinks for convenience
RUN ln -sf /usr/bin/powerpc-unknown-linux-gnu-gcc /usr/local/bin/gcc-ppc && \
    ln -sf /usr/bin/powerpc-unknown-linux-gnu-g++ /usr/local/bin/g++-ppc

# === Stage 2: Final Runtime Image ===
FROM gentoo/stage3:latest
LABEL maintainer="Felipe"
LABEL description="Distcc PowerPC-only runtime image"

ENV DISTCC_SAVE_TEMPS=1

# Install distcc only
RUN emerge-webrsync && \
    mkdir -p /etc/portage/package.accept_keywords && \
    echo "sys-devel/distcc" >> /etc/portage/package.accept_keywords/distcc && \
    emerge --quiet sys-devel/distcc

# Copy cross toolchain from builder
COPY --from=builder /usr/bin/powerpc-unknown-linux-gnu-* /usr/bin/
COPY --from=builder /usr/libexec/gcc /usr/libexec/gcc
COPY --from=builder /usr/lib/gcc /usr/lib/gcc
COPY --from=builder /usr/lib/distcc /usr/lib/distcc
COPY --from=builder /usr/local/bin/gcc-ppc /usr/local/bin/gcc-ppc
COPY --from=builder /usr/local/bin/g++-ppc /usr/local/bin/g++-ppc

# Whitelist compilers for distcc
RUN mkdir -p /usr/lib/distcc && \
    echo "/usr/bin/powerpc-unknown-linux-gnu-gcc" >> /usr/lib/distcc/whitelist && \
    echo "/usr/bin/powerpc-unknown-linux-gnu-g++" >> /usr/lib/distcc/whitelist

EXPOSE 3632
ENTRYPOINT ["distccd", "--daemon", "--no-fork", "--allow", "0.0.0.0/0", "--log-stderr", "--verbose", "--port", "3632"]