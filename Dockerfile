FROM gentoo/stage3:latest

ENV FEATURES="-ipc-sandbox -network-sandbox"
ENV USE="bindist -X"

# Sync the tree and unmask crossdev explicitly
RUN emerge-webrsync && \
    emerge --sync && \
    echo "sys-devel/crossdev" >> /etc/portage/package.accept_keywords/crossdev && \
    emerge --quiet sys-devel/crossdev sys-devel/distcc

# Set up overlay for crossdev
RUN mkdir -p /etc/portage/repos.conf && \
    mkdir -p /var/db/repos/localrepo && \
    echo '[localrepo]' > /etc/portage/repos.conf/localrepo.conf && \
    echo 'location = /var/db/repos/localrepo' >> /etc/portage/repos.conf/localrepo.conf && \
    echo 'masters = gentoo' >> /etc/portage/repos.conf/localrepo.conf && \
    echo 'auto-sync = no' >> /etc/portage/repos.conf/localrepo.conf

# Build the PPC toolchain
RUN crossdev --ov-output /var/db/repos/localrepo --target powerpc-unknown-linux-gnu

# Optional: symlink
RUN ln -s /usr/bin/powerpc-unknown-linux-gnu-gcc /usr/local/bin/gcc

EXPOSE 3632
ENTRYPOINT ["distccd", "--daemon", "--no-fork", "--allow", "0.0.0.0/0", "--log-stderr", "--verbose"]
