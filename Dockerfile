FROM gentoo/stage3:latest
LABEL stage="gcc14.2.1"
LABEL maintainer="Gentoo Crossdev by De Bene"
LABEL description="Gentoo Crossdev PowerPC cross-compiler with distcc support"

# 1) Enable distcc in FEATURES and allow crossdev
ENV FEATURES="-pid-sandbox -ipc-sandbox -network-sandbox distcc"
ENV USE="bindist -X cxx"

# 2) Sync and install crossdev + distcc
RUN emerge-webrsync && \
    mkdir -p /etc/portage/package.accept_keywords && \
    echo "sys-devel/crossdev" >> /etc/portage/package.accept_keywords/crossdev && \
    emerge --quiet sys-devel/crossdev sys-devel/distcc

# 3) Unmask and keyword GCC 14.2.1_p20241221 globally
RUN mkdir -p /etc/portage/package.accept_keywords && \
    mkdir -p /etc/portage/package.unmask && \
    echo "=sys-devel/gcc-14.2.1_p20241221 **" >> /etc/portage/package.accept_keywords/gcc && \
    echo "=sys-devel/gcc-14.2.1_p20241221" >> /etc/portage/package.unmask/gcc && \
    emerge --quiet =sys-devel/gcc-14.2.1_p20241221 && \
    gcc-config --list-profiles && \
    gcc-config 1

# 4) Unmask and keyword cross-toolchain
RUN echo "=cross-powerpc-unknown-linux-gnu/binutils-2.41*" >> /etc/portage/package.accept_keywords/cross-powerpc-unknown-linux-gnu && \
    echo "=cross-powerpc-unknown-linux-gnu/linux-headers-6.1*" >> /etc/portage/package.accept_keywords/cross-powerpc-unknown-linux-gnu && \
    echo "=cross-powerpc-unknown-linux-gnu/glibc-2.38*" >> /etc/portage/package.accept_keywords/cross-powerpc-unknown-linux-gnu && \
    echo "=cross-powerpc-unknown-linux-gnu/gcc-14.2.1" >> /etc/portage/package.accept_keywords/cross-powerpc-unknown-linux-gnu && \
    echo "=cross-powerpc-unknown-linux-gnu/gcc-14.2.1" >> /etc/portage/package.unmask/cross-powerpc-unknown-linux-gnu

# 5) Set up overlay for crossdev output
RUN mkdir -p /etc/portage/repos.conf /var/db/repos/localrepo && \
    cat <<EOF > /etc/portage/repos.conf/localrepo.conf
[localrepo]
location = /var/db/repos/localrepo
masters = gentoo
auto-sync = no
EOF

RUN mkdir -p /var/db/repos/localrepo/metadata && \
    echo "masters = gentoo" > /var/db/repos/localrepo/metadata/layout.conf

# 6) Build the cross-compiler toolchain with log
RUN crossdev --ov-output /var/db/repos/localrepo --target powerpc-unknown-linux-gnu --gcc 14.2.1_p20241221 > /crossdev.log || (cat /crossdev.log && exit 1)

# 7) Set ld.so search path for target sysroot
RUN echo "/usr/powerpc-unknown-linux-gnu/sys-root/usr/lib" > /etc/ld.so.conf.d/distcc.conf && \
    echo "/usr/powerpc-unknown-linux-gnu/sys-root/usr/lib64" >> /etc/ld.so.conf.d/distcc.conf && \
    ldconfig

# 8) Whitelist all cross-compiler binaries for distcc
RUN mkdir -p /usr/lib/distcc && \
    for bin in powerpc-unknown-linux-gnu-gcc  \
               powerpc-unknown-linux-gnu-g++  \
               powerpc-unknown-linux-gnu-cc   \
               powerpc-unknown-linux-gnu-c++  \
               powerpc-unknown-linux-gnu-ar   \
               powerpc-unknown-linux-gnu-ranlib \
               powerpc-unknown-linux-gnu-ld;   \
    do echo "/usr/bin/$bin" >> /usr/lib/distcc/whitelist; done

# 9) Unprefixed symlinks for convenience
RUN ln -sf /usr/bin/powerpc-unknown-linux-gnu-gcc /usr/local/bin/gcc && \
    ln -sf /usr/bin/powerpc-unknown-linux-gnu-g++ /usr/local/bin/g++ && \
    ln -sf /usr/bin/powerpc-unknown-linux-gnu-gcc /usr/bin/gcc && \
    ln -sf /usr/bin/powerpc-unknown-linux-gnu-g++ /usr/bin/g++

# 10) Verify compiler installed
RUN ls -l /usr/bin | grep powerpc-unknown-linux-gnu || echo "Cross-bin not installed"

EXPOSE 3632

ENTRYPOINT ["distccd", "--daemon", "--no-fork", "--allow", "0.0.0.0/0", "--log-stderr", "--verbose", "--port", "3632"]