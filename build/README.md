# Build acme-esxi VIB & Offline Bundle

The `create_vib.sh` bash script includes the commands needed to generate the VIB and Offline Bundle files. It relies on [vibauthor](https://hub.docker.com/r/lamw/vibauthor/), which depends on older Linux versions (such as CentOS 6).

Installing dependencies on the host looks like this (for a CenOS 6 host):

```
yum -y install tar openssl python-lxml glibc.i686 git file
```

Upon success, there should be a zip file named `acme-esxi-offline-bundle.zip` and a VIB file named `acme-esxi.vib` in the same directory as the `create_vib.sh` script.  Do note that CentOS 6 is well beyond end of life and should not be exposed to any environment where it may be compromised.
