FROM gentoo/stage3:latest

ENV FEATURES="-ipc-sandbox -network-sandbox"
ENV USE="bindist -X cxx"

# Sync the tree and install crossdev
RUN emerge-webrsync && \
    echo "sys-devel/crossdev" >> /etc/portage/package.accept_keywords/crossdev && \
    emerge --quiet sys-devel/crossdev

# Set up a local overlay for crossdev output
RUN mkdir -p /etc/portage/repos.conf /var/db/repos/localrepo && \
    printf '[localrepo]\nlocation = /var/db/repos/localrepo\nmasters = gentoo\nauto-sync = no\n' \
      > /etc/portage/repos.conf/localrepo.conf

# Build the full PowerPC toolchain including C++ runtime
RUN crossdev --stage2 --ov-output /var/db/repos/localrepo --target powerpc-unknown-linux-gnu

# Symlink gcc to the PowerPC cross-compiler for convenience
RUN ln -sf /usr/bin/powerpc-unknown-linux-gnu-gcc /usr/local/bin/gcc

# Whitelist cross-compiler binaries so distccd will accept both C and C++
# Whitelist cross-compiler binaries so distccd will accept both C and C++
RUN mkdir -p /usr/lib/distcc && \
    ln -sf /usr/bin/powerpc-unknown-linux-gnu-gcc  /usr/lib/distcc/powerpc-unknown-linux-gnu-gcc && \
    ln -sf /usr/bin/powerpc-unknown-linux-gnu-g++  /usr/lib/distcc/powerpc-unknown-linux-gnu-g++ && \
    echo "powerpc-unknown-linux-gnu-gcc" > /usr/lib/distcc/whitelist && \
    echo "powerpc-unknown-linux-gnu-g++" >> /usr/lib/distcc/whitelist

# Install distcc daemon
RUN emerge --quiet sys-devel/distcc

EXPOSE 3632

ENTRYPOINT ["distccd", "--no-fork", "--no-detach", "--allow=0.0.0.0/0", "--log-stderr", "--verbose"]