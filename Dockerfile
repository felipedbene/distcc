FROM gentoo/stage3:latest

# 1) Enable distcc in FEATURES and allow crossdev
ENV FEATURES="-ipc-sandbox -network-sandbox distcc"
ENV USE="bindist -X cxx"

# 2) Sync and pull in crossdev + distcc
RUN emerge-webrsync && \
    echo "sys-devel/crossdev" >> /etc/portage/package.accept_keywords && \
    emerge --quiet sys-devel/crossdev sys-devel/distcc

# 3) Set up your overlay for crossdev
RUN mkdir -p /etc/portage/repos.conf /var/db/repos/localrepo && \
    cat <<EOF > /etc/portage/repos.conf/localrepo.conf
[localrepo]
location = /var/db/repos/localrepo
masters = gentoo
auto-sync = no
EOF

# 4) Build the PPC cross-toolchain
RUN crossdev --ov-output /var/db/repos/localrepo --target powerpc-unknown-linux-gnu

# ──────────────────────────────────────────────────────────────────────────────
# 5) **NEW**: pull in the *target* C++ runtime packages so your node can link:
RUN emerge --quiet \
      powerpc-unknown-linux-gnu-libstdc++ \
      powerpc-unknown-linux-gnu-libgcc \
      sys-libs/libunwind

# 6) **NEW**: ensure the cross-sys-root’s lib dirs are on your ld search path
RUN echo "/usr/powerpc-unknown-linux-gnu/sys-root/usr/lib" > /etc/ld.so.conf.d/distcc.conf && \
    echo "/usr/powerpc-unknown-linux-gnu/sys-root/usr/lib64" >> /etc/ld.so.conf.d/distcc.conf && \
    ldconfig

# 7) Whitelist *all* of the cross-compiler toolchain so distcc can invoke them:
RUN mkdir -p /usr/lib/distcc && \
    for bin in powerpc-unknown-linux-gnu-gcc  \
               powerpc-unknown-linux-gnu-g++  \
               powerpc-unknown-linux-gnu-cc   \
               powerpc-unknown-linux-gnu-c++  \
               powerpc-unknown-linux-gnu-ar   \
               powerpc-unknown-linux-gnu-ranlib \
               powerpc-unknown-linux-gnu-ld;   \
    do echo "/usr/bin/$bin" >> /usr/lib/distcc/whitelist; done

# 8) (Optional) if you want unprefixed gcc/g++ names in PATH for ease of use
RUN ln -sf /usr/bin/powerpc-unknown-linux-gnu-gcc /usr/local/bin/gcc && \
    ln -sf /usr/bin/powerpc-unknown-linux-gnu-g++ /usr/local/bin/g++

EXPOSE 3632

ENTRYPOINT ["distccd", "--daemon", "--no-fork", "--allow", "0.0.0.0/0", "--log-stderr", "--verbose", "--port", "3632"]