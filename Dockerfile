FROM gentoo/stage3:latest

# 1) Enable distcc in FEATURES and allow crossdev
ENV FEATURES="-ipc-sandbox -network-sandbox distcc"
ENV USE="bindist -X cxx"

# 2) Sync and pull in crossdev + distcc
RUN emerge-webrsync && \
    mkdir -p /etc/portage/package.accept_keywords && \
    echo "sys-devel/crossdev" >> /etc/portage/package.accept_keywords/crossdev && \
    emerge --quiet sys-devel/crossdev sys-devel/distcc

# 3) Set up overlay for crossdev output
RUN mkdir -p /etc/portage/repos.conf /var/db/repos/localrepo && \
    cat <<EOF > /etc/portage/repos.conf/localrepo.conf
[localrepo]
location = /var/db/repos/localrepo
masters = gentoo
auto-sync = no
EOF

# 4) Build the PPC cross-toolchain using GCC 14
RUN crossdev --ov-output /var/db/repos/localrepo --target powerpc-unknown-linux-gnu --gcc 14.2.1

# 5) Set ld.so search path for target sysroot
RUN echo "/usr/powerpc-unknown-linux-gnu/sys-root/usr/lib" > /etc/ld.so.conf.d/distcc.conf && \
    echo "/usr/powerpc-unknown-linux-gnu/sys-root/usr/lib64" >> /etc/ld.so.conf.d/distcc.conf && \
    ldconfig

# 6) Whitelist all cross-compiler binaries for distcc
RUN mkdir -p /usr/lib/distcc && \
    for bin in powerpc-unknown-linux-gnu-gcc  \
               powerpc-unknown-linux-gnu-g++  \
               powerpc-unknown-linux-gnu-cc   \
               powerpc-unknown-linux-gnu-c++  \
               powerpc-unknown-linux-gnu-ar   \
               powerpc-unknown-linux-gnu-ranlib \
               powerpc-unknown-linux-gnu-ld;   \
    do echo "/usr/bin/$bin" >> /usr/lib/distcc/whitelist; done

# 7) Unprefixed symlinks for convenience
RUN ln -sf /usr/bin/powerpc-unknown-linux-gnu-gcc /usr/local/bin/gcc && \
    ln -sf /usr/bin/powerpc-unknown-linux-gnu-g++ /usr/local/bin/g++

# 8) Set GCC 14 as the active version and load updated environment
RUN gcc-config powerpc-unknown-linux-gnu-14 && . /etc/profile

# 9) Sanity check the toolchain selection
RUN gcc-config -l && gcc -v

# 10) Verify cross-compiler works
RUN powerpc-unknown-linux-gnu-gcc --version

EXPOSE 3632

ENTRYPOINT ["distccd", "--daemon", "--no-fork", "--allow", "0.0.0.0/0", "--log-stderr", "--verbose", "--port", "3632"]