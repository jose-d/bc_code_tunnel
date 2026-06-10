# VS Code Tunnel for Open OnDemand

An Open OnDemand Batch Connect app that launches a VS Code Remote Tunnel inside
a Slurm job. The app starts the tunnel on a compute node, shows tunnel status in
the browser, and lets users connect from their local VS Code client through the
Remote Tunnels workflow.

## Features

- Runs VS Code Remote Tunnel inside a scheduled Slurm allocation.
- Keeps the browser view limited to status and login output through `ttyd`.
- Lets users authenticate with their own GitHub account through device login.
- Keeps site-specific cluster, partition, resource, path, and submit settings in
  one local `site.yml` file.
- Cleans up the tunnel registration and background helper process when the job
  exits.

## Requirements

- Open OnDemand with Batch Connect support.
- Slurm as the scheduler.
- VS Code CLI (`code`) available on compute nodes.
- `ttyd` available on compute nodes.
- `ripgrep` (`rg`) available on compute nodes for status parsing.
- Outbound network access from compute nodes to the VS Code / GitHub tunnel
  services required by VS Code Remote Tunnels.
- Users must be able to authenticate to GitHub device login.

The app has been written for a system app deployment, but the same files can be
installed as a user app for testing.

## Installation

1. Clone this repository on an Open OnDemand web node.

   ```bash
   git clone https://github.com/jose-d/bc_code_tunnel.git
   ```

2. Install the app as a system app.

   ```bash
   sudo mkdir -p /var/www/ood/apps/sys/code_tunnel
   sudo rsync -a --delete bc_code_tunnel/ /var/www/ood/apps/sys/code_tunnel/
   ```

3. Create the site-local configuration file.

   ```bash
   sudo cp /var/www/ood/apps/sys/code_tunnel/site.yml.example \
     /etc/ood/apps/sys/code_tunnel/site.yml
   ```

4. Edit `/etc/ood/apps/sys/code_tunnel/site.yml` for your cluster.

5. Refresh the Open OnDemand dashboard according to your site policy. For
   example:

   ```bash
   sudo touch /var/www/ood/apps/sys/dashboard/tmp/restart.txt
   ```

## Configuration

By default the app reads:

```text
/etc/ood/apps/sys/code_tunnel/site.yml
```

You can override this path with:

```bash
OOD_CODE_TUNNEL_SITE_CONFIG=/path/to/site.yml
```

Copy [site.yml.example](site.yml.example) and adjust these values:

| Key | Required | Description |
| --- | --- | --- |
| `cluster` | Yes | Open OnDemand cluster ID from `clusters.d`. |
| `default_partition` | Yes | Default Slurm partition shown in the form. |
| `partition_help` | No | Help text shown under the partition selector. |
| `partitions` | Yes | List of `[label, value]` partition options. |
| `hours` | Yes | List of `[label, value]` wall-time options in hours. |
| `default_hours` | Yes | Default wall time value. |
| `cpus` | Yes | List of `[label, value]` CPU-count options. |
| `default_num_cpus` | Yes | Default CPU count. |
| `memory_gb` | Yes | List of `[label, value]` memory options in GB. |
| `default_memory_gb` | Yes | Default memory in GB. |
| `submit_native` | No | Extra Slurm arguments passed under `script.native`. |
| `paths.code` | No | Absolute path to the VS Code CLI. Falls back to `PATH`. |
| `paths.ttyd` | No | Absolute path to `ttyd`. Falls back to `PATH`. |

Example:

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

paths:
  code: /usr/bin/code
  ttyd: /usr/bin/ttyd
```

## User Workflow

1. Launch the app from Open OnDemand.
2. Open the browser status view.
3. Follow the GitHub device-login prompt shown by the VS Code CLI.
4. Open local VS Code.
5. Use Remote Explorer, then Tunnels, and connect to the tunnel name shown in
   the session view.

Closing the browser status view does not stop the Slurm job. End the Open
OnDemand session when the tunnel is no longer needed.

## Testing

After deployment, verify the app with:

```bash
bash -n template/before.sh template/script.sh template/after.sh \
  template/ttyd.sh template/bin/status-tail.sh \
  template/bin/update-tunnel-info.sh
```

Then submit a short test session through Open OnDemand and confirm:

- the Slurm job starts on the expected partition,
- the status view opens,
- the GitHub device login appears,
- the tunnel appears in local VS Code,
- ending the OOD session terminates the tunnel process.

This app has been tested on Open OnDemand deployments using Slurm and compute
nodes with `code`, `ttyd`, and `rg` installed.

## Troubleshooting

### The form shows `CHANGE_ME` as the cluster

Create or fix `site.yml` and set `cluster` to an Open OnDemand cluster ID known
to the web node.

### The job starts but no tunnel appears

Check the session output and verify that `code` is installed on the compute node.
If it is not on `PATH`, set `paths.code` in `site.yml`.

### The status view does not open

Verify that `ttyd` is installed on the compute node. If it is not on `PATH`, set
`paths.ttyd` in `site.yml`.

### Login never completes

Confirm the user completed GitHub device login in the browser and that compute
nodes can reach the external services required by VS Code Remote Tunnels.

### The job is submitted to the wrong partition or account

Review `partitions`, `default_partition`, and `submit_native` in `site.yml`.
These values are intentionally site-local.

## Known Limitations

- Slurm is required.
- Users authenticate tunnels with their own GitHub accounts.
- The app does not expose a browser-based shell; the browser view is for status
  only.
- Network-restricted compute nodes may not be able to establish VS Code tunnels.
- The app does not install VS Code CLI, `ttyd`, or `rg`; deployers must provide
  them on compute nodes.

## Support

Open app-specific issues at:

```text
https://github.com/jose-d/bc_code_tunnel/issues
```

For Open OnDemand platform issues unrelated to this app, use the Open OnDemand
community support channels.
