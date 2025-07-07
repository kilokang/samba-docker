FROM ubuntu:24.04@sha256:440dcf6a5640b2ae5c77724e68787a906afb8ddee98bf86db94eea8528c2c076 AS build
ARG SAMBA_VERSION=4.22.3
ARG MODULES_AUTH="auth_unix,auth_wbc,auth_server,auth_netlogond,auth_script,auth_samba4"
ARG MODULES_IDMAP="idmap_ad,idmap_rid,idmap_adex,idmap_hash,idmap_tdb2"
ARG MODULES_PDB="pdb_tdbsam,pdb_ldap,pdb_ads,pdb_smbpasswd,pdb_wbc_sam,pdb_samba4"
ARG MODULES_VFS="vfs_acl_xattr,vfs_aio_fork,vfs_aio_pthread,vfs_audit,vfs_btrfs,vfs_cacheprime,vfs_cap,vfs_catia,vfs_ceph,vfs_ceph_snapshots,vfs_commit,vfs_crossrename,vfs_default_quota,vfs_delay_inject,vfs_dfs_samba4,vfs_dirsort,vfs_fileid,vfs_fruit,vfs_full_audit,vfs_io_uring,vfs_nfs4acl_xattr,vfs_offline,vfs_posix_eadb,vfs_preopen,vfs_readahead,vfs_readonly,vfs_recycle,vfs_shadow_copy2,vfs_shell_snap,vfs_snapper,vfs_streams_depot,vfs_streams_xattr,vfs_syncops,vfs_time_audit,vfs_unityed_media,vfs_virusfilter,vfs_widelinks,vfs_worm,vfs_zfs"

RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    apt-get -y update && \
    apt-get -y install curl

RUN curl -sSL https://download.samba.org/pub/samba/stable/samba-$SAMBA_VERSION.tar.gz | tar xzf -
WORKDIR samba-$SAMBA_VERSION

# Deps sourced from https://gitlab.com/samba-team/samba/-/blob/5a582bddd834fffe2b27cc8b2e9468fa84dfc6f2/bootstrap/generated-dists/ubuntu2404/packages.yml
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    apt-get -y install \
    bison \
    build-essential \
    flex \
    glusterfs-common \
    gnutls-bin \
    heimdal-multidev \
    krb5-config \
    krb5-kdc \
    krb5-user \
    libacl1-dev \
    libarchive-dev \
    libattr1-dev \
    libblkid-dev \
    libbsd-dev \
    libcap-dev \
    libcephfs-dev \
    libclang-dev \
    libcups2-dev \
    libevent-dev \
    libglib2.0-dev \
    libgnutls28-dev \
    libicu-dev \
    libjansson-dev \
    libkeyutils-dev \
    libkrb5-dev \
    libldap2-dev \
    liblmdb-dev \
    libparse-yapp-perl \
    libpcap-dev \
    libpopt-dev \
    libreadline-dev \
    libssl-dev \
    libtasn1-bin \
    libtasn1-dev \
    libunwind-dev \
    liburing-dev \
    libutf8proc-dev \
    lmdb-utils \
    pkg-config \
    python3 \
    python3-cryptography \
    python3-dbg \
    python3-dev \
    python3-dnspython \
    python3-gpg \
    python3-iso8601 \
    python3-markdown \
    python3-pyasn1 \
    python3-requests \
    python3-setproctitle \
    xfslibs-dev \
    zlib1g-dev

RUN ./configure --jobs=$((`nproc` - 1)) \
    --enable-fhs \
    --prefix=/usr \
    --sysconfdir=/etc \
    --sbindir=/usr/bin \
    --libdir=/usr/lib \
    --libexecdir=/usr/lib/samba \
    --localstatedir=/var \
    --with-configdir=/etc/samba \
    --with-lockdir=/var/cache/samba \
    --with-sockets-dir=/run \
    --with-piddir=/run \
    --with-logfilebase=/var/log/samba \
    \
    --without-gettext \
    --without-gpgme \
    --without-systemd \
    --without-pam \
    --without-winbind \
    --disable-avahi \
    --disable-rpath-install \
    --disable-fault-handling \
    --with-profiling-data \
    \
    --with-ads \
    --enable-cups \
    --enable-ceph-reclock \
    --with-smb1-server \
    \
    --bundled-libraries=ALL \
    --with-shared-modules="$MODULES_AUTH,$MODULES_IDMAP,$MODULES_PDB,$MODULES_VFS"

RUN make -j$((`nproc` - 1))
RUN make DESTDIR="/target/" install -j$((`nproc` - 1))


FROM ubuntu:24.04@sha256:440dcf6a5640b2ae5c77724e68787a906afb8ddee98bf86db94eea8528c2c076

RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    apt-get -y update && \
    apt-get -y install binutils

RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    apt-get -y update && \
    apt-get -y install \
    libbsd0 \
    libicu74 \
    libjansson4 \
    libkeyutils1 \
    libldap2

COPY --from=build /target/ /

ENTRYPOINT [ "/usr/bin/smbd", "--interactive", "--foreground", "--no-process-group" ]
