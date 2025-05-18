FROM gentoo/stage3:latest

ENV FEATURES="-ipc-sandbox -network-sandbox"
ENV USE="bindist -X cxx"

# Sync Portage and install crossdev
RUN emerge-webrsync && \
    echo "sys-devel/crossdev" >> /etc/portage/package.accept_keywords/crossdev && \
    emerge --quiet sys-devel/crossdev sys-devel/distcc

# Set up local overlay for crossdev output
RUN mkdir -p /etc/portage/repos.conf /var/db/repos/localrepo && \
    printf '[x-localrepo]\nlocation = /var/db/repos/localrepo\nmasters = gentoo\nauto-sync = no\n' > /etc/portage/repos.conf/localrepo.conf && \
    mkdir -p /var/db/repos/localrepo/metadata && \
    echo 'masters = gentoo' > /var/db/repos/localrepo/metadata/layout.conf

# Build PowerPC cross toolchain
RUN crossdev --target powerpc-unknown-linux-gnu

# Set toolchain PATH dynamically and persist it
RUN GCC_BIN_DIR=$(ls /usr/powerpc-unknown-linux-gnu/gcc-bin | head -n1) && \
    echo "export PATH=/usr/powerpc-unknown-linux-gnu/gcc-bin/${GCC_BIN_DIR}:\$PATH" > /etc/profile.d/crossdev-path.sh

ENV PATH="/usr/powerpc-unknown-linux-gnu/gcc-bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Whitelist cross-compilers for distcc
RUN mkdir -p /usr/lib/distcc && \
    ln -sf $(which powerpc-unknown-linux-gnu-gcc) /usr/lib/distcc/powerpc-unknown-linux-gnu-gcc && \
    ln -sf $(which powerpc-unknown-linux-gnu-g++) /usr/lib/distcc/powerpc-unknown-linux-gnu-g++ && \
    echo "powerpc-unknown-linux-gnu-gcc" > /usr/lib/distcc/whitelist && \
    echo "powerpc-unknown-linux-gnu-g++" >> /usr/lib/distcc/whitelist

# Expose distccd port and run it as the main process
EXPOSE 3632

ENTRYPOINT ["distccd", "--daemon", "--no-fork", "--allow", "0.0.0.0/0", "--log-stderr"]