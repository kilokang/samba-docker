FROM alpine:3.18.4 AS build
ARG SAMBA_VERSION=4.18.3

# Deps sourced from https://git.alpinelinux.org/aports/tree/main/samba/APKBUILD
RUN apk add build-base coreutils \
            py3-dnspython py3-markdown tdb acl-dev bind-dev cups-dev dbus-dev docbook-xsl \
            e2fsprogs-dev fuse-dev gnutls-dev iniparser-dev jansson-dev ldb-dev libarchive-dev \
            libcap-dev libtirpc-dev liburing-dev linux-pam-dev musl-nscd-dev ncurses-dev \
            openldap-dev perl perl-json perl-parse-yapp popt-dev py3-ldb py3-tdb py3-tevent \
            python3-dev rpcgen subunit-dev talloc-dev tdb-dev tevent-dev zlib-dev \
            ceph-dev


RUN wget https://download.samba.org/pub/samba/stable/samba-$SAMBA_VERSION.tar.gz -O- | tar xzf -
WORKDIR samba-$SAMBA_VERSION

ARG MODULES_BUNDLED="cmocka,vfs_default,vfs_posixacl"
ARG MODULES_ALPINE_DEFAULT="roken,wind,hx509,asn1,heimbase,hcrypto,krb5,gssapi,heimntlm,hdb,kdc"
ARG MODULES_AUTH="auth4_anonymous,auth4_sam_module,auth_netlogond,auth_samba4,auth_script,auth_server,auth_unix,auth_wbc"
ARG MODULES_IDMAP="idmap_ad,idmap_adex,idmap_hash,idmap_ldap,idmap_nss,idmap_passdb,idmap_rfc2307,idmap_rid,idmap_script,idmap_tdb2"
ARG MODULES_LDB="ldb_acl,ldb_aclread,ldb_audit_log,ldb_descriptor,ldb_dirsync,ldb_dns_notify,ldb_dsdb_notification,ldb_encrypted_secrets,ldb_ldb,ldb_mdb,ldb_objectclass,ldb_objectclass_attrs,ldb_password_hash,ldb_samba3sam,ldb_samba3sid,ldb_samba_dsdb,ldb_sqlite3"
ARG MODULES_NSS="nss_info_hash,nss_info_rfc2307"
ARG MODULES_PDB="pdb_ads,pdb_ldap,pdb_ldapsam,pdb_samba_dsdb,pdb_samba4,pdb_smbpasswd,pdb_tdbsam,pdb_wbc_sam"
ARG MODULES_VFS="vfs_acl_xattr,vfs_aio_fork,vfs_aio_pthread,vfs_audit,vfs_btrfs,vfs_cacheprime,vfs_cap,vfs_catia,vfs_ceph,vfs_ceph_snapshots,vfs_commit,vfs_crossrename,vfs_default_quota,vfs_delay_inject,vfs_dfs_samba4,vfs_dirsort,vfs_fileid,vfs_fruit,vfs_full_audit,vfs_io_uring,vfs_nfs4acl_xattr,vfs_offline,vfs_posix_eadb,vfs_preopen,vfs_readahead,vfs_readonly,vfs_recycle,vfs_shadow_copy2,vfs_shell_snap,vfs_snapper,vfs_streams_depot,vfs_streams_xattr,vfs_syncops,vfs_time_audit,vfs_unityed_media,vfs_virusfilter,vfs_widelinks,vfs_worm"

RUN ./configure --jobs=$((`nproc` - 1)) \
    --enable-fhs \
    --prefix=/usr \
    --sbindir=/usr/bin \
    --libexecdir=/usr/lib \
    --sysconfdir=/etc/samba \
    --with-configdir=/etc/samba \
    --localstatedir=/var \
    --with-lockdir=/var/cache/samba \
    --with-logfilebase=/var/log/samba \
    --with-sockets-dir=/run/samba \
    --with-piddir=/run \
    \
    --without-gettext \
    --without-gpgme \
    --without-systemd \
    --without-pam \
    --without-winbind \
    --disable-avahi \
    --disable-rpath-install \
    --disable-fault-handling \
    \
    --with-ads \
    --enable-cups \
    --enable-ceph-reclock \
    --with-smb1-server \
    \
    --bundled-libraries="NONE,$MODULES_BUNDLED" \
    --with-shared-modules="$MODULES_ALPINE_DEFAULT,$MODULES_AUTH,$MODULES_IDMAP,$MODULES_LDB,$MODULES_NSS,$MODULES_PDB,$MODULES_VFS"
RUN make -j$((`nproc` - 1))
RUN make DESTDIR="/target/" install -j$((`nproc` - 1))


FROM alpine:3.18.4
### RUN addgroup -S samba && \
###     adduser -S -D -H -h /dev/null -s /sbin/nologin -G samba -g samba samba

RUN apk add gnutls talloc tevent zlib tdb ldb acl jansson libcap liburing openldap popt

COPY --from=build /target/ /

ENTRYPOINT [ "/usr/bin/smbd", "--interactive", "--foreground", "--no-process-group" ]
