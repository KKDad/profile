## Docker / Podman remote connections

Formalizes the `portainer` remote host (`ssh://root@portainer.stapledon.ca`) as a reusable, idempotent connection instead of a one-off manual command. Run directly (`bash docker/setup.sh`) or via `ubuntu/setup.sh`.

Two mechanisms depending on the machine:

- **Mac (real `docker` CLI installed, e.g. via `homebrew/Brewfile.laptop`)** — uses `docker context`:
  - `docker context use podman` — local, via the podman socket (`podman info --format '{{.Host.RemoteSocket.Path}}'`)
  - `docker context use portainer` — remote, `ssh://root@portainer.stapledon.ca`
  - Don't set `DOCKER_HOST` — it overrides context selection.
- **Ubuntu (podman only — docker is deprecated there, podman is a full replacement)** — uses `podman system connection`:
  - Local use is just the bare `podman` command, no connection needed.
  - `podman --connection portainer <cmd>` or `podman system connection default portainer` — remote, `ssh://root@portainer.stapledon.ca`

Requires SSH access to `root@portainer.stapledon.ca` from whichever machine runs this. The `~/.ssh/config` Host block, `known_hosts` entry, and `stapledon.ca` DNS search domain are set up by `ubuntu/setup.sh` (step 10) — if you're running this script standalone on a box that hasn't gone through that, make sure the equivalent is in place first. Either way, key auth itself (the `id_kkdad` private key) is set up out of band — not managed by this repo.

Manual equivalent, if you ever need to redo this by hand:
```bash
# docker CLI
docker context create portainer --docker "host=ssh://root@portainer.stapledon.ca"

# podman only
podman system connection add portainer ssh://root@portainer.stapledon.ca/run/podman/podman.sock
```
