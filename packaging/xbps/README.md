# XBPS packaging moved to z-packages

The Void Linux templates for this project live in
[SrDicov/z-packages](https://github.com/SrDicov/z-packages) and are
built/published to [SrDicov/z-repo](https://github.com/SrDicov/z-repo).

- `srcpkgs/labwc-singularity` — the compositor fork and its patched scenefx.
- `srcpkgs/singularity-desktop` — the desktop, with every bundled
  subproject pinned as a distfile and the gesture runtime assets.

Do not keep copies here: they drift. Update the z-packages templates and
let the z-repo autobuild publish the binaries.

To install from z-repo, follow the README in that repository:

```sh
fp=02:16:21:e8:80:43:b6:16:d4:63:13:e5:5d:e1:32:b7
mkdir -p /var/db/xbps/keys /etc/xbps.d
curl -fsSL -o "/var/db/xbps/keys/$fp.plist" \
  "https://github.com/SrDicov/z-repo/releases/download/stable/${fp//:/.}.plist"
echo "repository=https://github.com/SrDicov/z-repo/releases/download/stable" \
  > /etc/xbps.d/10-zrepo.conf
xbps-install -S
xbps-install singularity-desktop
```
