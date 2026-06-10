# VS Code Tunnel for Open OnDemand

This app is derived from a Batch Shell-style app, but it launches a VS Code
Remote Tunnel inside a Slurm job instead of an interactive tmux/screen shell.

Design notes:

- The app remains an Open OnDemand `batch_connect` app so it can reuse the
  existing Slurm submission and session lifecycle.
- The browser "Connect" button opens a status/log viewer backed by `ttyd`.
- Users complete GitHub device login in the browser, then attach from local
  VS Code using the Remote Tunnels workflow.
- The app does not expose an interactive shell in the browser.

Site-local configuration

This repo can stay generic. Site-specific strings and paths can live in a
local config file outside the repo:

- default path: `/etc/ood/apps/sys/code_tunnel/site.yml`
- override path: `OOD_CODE_TUNNEL_SITE_CONFIG=/path/to/site.yml`

The app reads that file from `form.yml.erb`, `submit.yml.erb`, and
`template/form.sh.erb`.

Supported keys:

```yaml
cluster: my_cluster
default_partition: compute
partition_help: Use GPU partitions only if your site permits them.
partitions:
  - [Compute, compute]
  - [GPU, gpu]
hours:
  - [4 hours, "4"]
  - [8 hours, "8"]
default_hours: "8"
cpus:
  - ["4", "4"]
  - ["8", "8"]
default_num_cpus: "4"
memory_gb:
  - ["16", "16"]
  - ["32", "32"]
default_memory_gb: "16"
submit_native:
  - --account=your_slurm_account
  - --constraint=interactive
paths:
  code: /usr/bin/code
  ttyd: /usr/bin/ttyd
```

See [site.yml.example](site.yml.example) for a ready-to-copy example.

Local assumptions:

- users authenticate their own tunnels with GitHub device login
- `code` and `ttyd` are either on `PATH` or configured in `site.yml`

Deployment model:

1. Deploy the generic app body from this repo.
2. Add `/etc/ood/apps/sys/code_tunnel/site.yml` on the target site.
3. Restart or refresh the OOD app as needed for your environment.
