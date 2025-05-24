# === Stage 1: Full Build with Logs and Toolchains ===
FROM gentoo/stage3:latest AS builder
LABEL maintainer="Felipe"
LABEL description="Build stage for cross-toolchain distcc (PowerPC + ARM64)"

ENV FEATURES="-pid-sandbox -ipc-sandbox -network-sandbox distcc"
ENV USE="bindist -X cxx"
ENV DISTCC_SAVE_TEMPS=1

# Sync and install base tools
RUN emerge-webrsync && \
    mkdir -p /etc/portage/package.accept_keywords && \
    echo "sys-devel/crossdev" >> /etc/portage/package.accept_keywords/crossdev && \
    emerge --quiet sys-devel/crossdev sys-devel/distcc

# Install system GCC 14.2.1_p20241221
RUN mkdir -p /etc/portage/package.unmask && \
    echo "=sys-devel/gcc-14.2.1_p20241221 **" >> /etc/portage/package.accept_keywords/gcc && \
    echo "=sys-devel/gcc-14.2.1_p20241221" >> /etc/portage/package.unmask/gcc && \
    emerge --quiet =sys-devel/gcc-14.2.1_p20241221 && \
    gcc-config 1

# Configure overlay for crossdev output
RUN mkdir -p /etc/portage/repos.conf /var/db/repos/localrepo && \
    echo "[localrepo]" > /etc/portage/repos.conf/localrepo.conf && \
    echo "location = /var/db/repos/localrepo" >> /etc/portage/repos.conf/localrepo.conf && \
    echo "masters = gentoo" >> /etc/portage/repos.localrepo/metadata/layout.conf && \
    echo "auto-sync = no" >> /etc/portage/repos.conf/localrepo.conf

# --- Build PPC cross toolchain ---
RUN echo "=cross-powerpc-unknown-linux-gnu/gcc-14.2.1_p20241221" >> /etc/portage/package.accept_keywords/cross-powerpc-unknown-linux-gnu && \
    echo "=cross-powerpc-unknown-linux-gnu/gcc-14.2.1_p20241221" >> /etc/portage/package.unmask/cross-powerpc-unknown-linux-gnu && \
    echo "=cross-powerpc-unknown-linux-gnu/binutils-2.41*" >> /etc/portage/package.accept_keywords/cross-powerpc-unknown-linux-gnu && \
    echo "=cross-powerpc-unknown-linux-gnu/linux-headers-6.1*" >> /etc/portage/package.accept_keywords/cross-powerpc-unknown-linux-gnu && \
    echo "=cross-powerpc-unknown-linux-gnu/glibc-2.38*" >> /etc/portage/package.accept_keywords/cross-powerpc-unknown-linux-gnu && \
    crossdev --ov-output /var/db/repos/localrepo --target powerpc-unknown-linux-gnu --gcc 14.2.1_p20241221 > /crossdev-ppc.log || (cat /crossdev-ppc.log && exit 1)

# --- Build ARM64 cross toolchain ---
RUN echo "=cross-aarch64-unknown-linux-gnu/gcc-14.2.1_p20241221" >> /etc/portage/package.accept_keywords/cross-aarch64-unknown-linux-gnu && \
    echo "=cross-aarch64-unknown-linux-gnu/gcc-14.2.1_p20241221" >> /etc/portage/package.unmask/cross-aarch64-unknown-linux-gnu && \
    echo "=cross-aarch64-unknown-linux-gnu/binutils-2.41*" >> /etc/portage/package.accept_keywords/cross-aarch64-unknown-linux-gnu && \
    echo "=cross-aarch64-unknown-linux-gnu/linux-headers-6.1*" >> /etc/portage/package.accept_keywords/cross-aarch64-unknown-linux-gnu && \
    echo "=cross-aarch64-unknown-linux-gnu/glibc-2.38*" >> /etc/portage/package.accept_keywords/cross-aarch64-unknown-linux-gnu && \
    crossdev --ov-output /var/db/repos/localrepo --target aarch64-unknown-linux-gnu --gcc 14.2.1_p20241221 > /crossdev-arm64.log || (cat /crossdev-arm64.log && exit 1)

# Symlink helpers (optional)
RUN ln -sf /usr/bin/powerpc-unknown-linux-gnu-gcc /usr/local/bin/gcc-ppc && \
    ln -sf /usr/bin/aarch64-unknown-linux-gnu-gcc /usr/local/bin/gcc-arm64

# === Stage 2: Minimal runtime with just compilers + distcc ===
FROM gentoo/stage3:latest
LABEL maintainer="Felipe"
LABEL description="Final distcc runtime with PowerPC and ARM64 cross toolchains"

ENV DISTCC_SAVE_TEMPS=1

# Install distcc only
RUN emerge-webrsync && \
    mkdir -p /etc/portage/package.accept_keywords && \
    echo "sys-devel/distcc" >> /etc/portage/package.accept_keywords/distcc && \
    emerge --quiet sys-devel/distcc

# Copy compiled toolchains from builder
COPY --from=builder /usr/bin/powerpc-unknown-linux-gnu-* /usr/bin/
COPY --from=builder /usr/bin/aarch64-unknown-linux-gnu-* /usr/bin/
COPY --from=builder /usr/libexec/gcc /usr/libexec/gcc
COPY --from=builder /usr/lib/gcc /usr/lib/gcc
COPY --from=builder /usr/lib/distcc /usr/lib/distcc
COPY --from=builder /usr/local/bin/gcc-* /usr/local/bin/

# Whitelist toolchain binaries for distcc
RUN mkdir -p /usr/lib/distcc && \
    echo "/usr/bin/powerpc-unknown-linux-gnu-gcc" >> /usr/lib/distcc/whitelist && \
    echo "/usr/bin/powerpc-unknown-linux-gnu-g++" >> /usr/lib/distcc/whitelist && \
    echo "/usr/bin/aarch64-unknown-linux-gnu-gcc" >> /usr/lib/distcc/whitelist && \
    echo "/usr/bin/aarch64-unknown-linux-gnu-g++" >> /usr/lib/distcc/whitelist

EXPOSE 3632
ENTRYPOINT ["distccd", "--daemon", "--no-fork", "--allow", "0.0.0.0/0", "--log-stderr", "--verbose", "--port", "3632"]