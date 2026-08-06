## Docker / Podman remote connections

Formalizes the `portainer` remote host (`ssh://root@10.0.0.47`) as a reusable, idempotent connection instead of a one-off manual command. Run directly (`bash docker/setup.sh`) or via `ubuntu/setup.sh`.

Two mechanisms depending on the machine:

- **Mac (real `docker` CLI installed, e.g. via `homebrew/Brewfile.laptop`)** — uses `docker context`:
  - `docker context use podman` — local, via the podman socket (`podman info --format '{{.Host.RemoteSocket.Path}}'`)
  - `docker context use portainer` — remote, `ssh://root@10.0.0.47`
  - Don't set `DOCKER_HOST` — it overrides context selection.
- **Ubuntu (podman only — docker is deprecated there, podman is a full replacement)** — uses `podman system connection`:
  - Local use is just the bare `podman` command, no connection needed.
  - `podman --connection portainer <cmd>` or `podman system connection default portainer` — remote, `ssh://root@10.0.0.47`

Requires SSH access to `root@10.0.0.47` from whichever machine runs this (key auth already set up out of band — not managed by this repo).

Manual equivalent, if you ever need to redo this by hand:
```bash
# docker CLI
docker context create portainer --docker "host=ssh://root@10.0.0.47"

# podman only
podman system connection add portainer ssh://root@10.0.0.47/run/podman/podman.sock
```
