## Kubernetes 1.5.2

### Upgrading to this Version

If you are trying to create resiliency planes by labeling your hosts to separate out the data, orchestration and compute planes, you **must** change the plane isolation option to `required`. The host labels, `compute=true`, `orchestration=true` and `etcd=true`, are required on your hosts in order for Kubernetes to successfully launch. By default, `none` is selected and there will be not attempt for plane isolation.

### Plane Isolation

If you set the "Plane Isolation" field to `required`, the host labels, `compute=true`, `orchestration=true` and `etcd=true`, are required on your hosts in order for Kubernetes to successfully launch.

### KubeDNS

KubeDNS is enabled for name resolution as described in the [Kubernetes DNS docs](http://kubernetes.io/docs/admin/dns/). The DNS service IP address is `10.43.0.10`.

### Backup Configuration

Backups are enabled/disabled via the `Enable Backups` radio buttons.

The backup period durations must be a sequence of decimal numbers, each with optional fraction and a unit suffix, such as `300ms`, `1.5h` or `2h45m`. Valid time units are `ns`, `us` or `µs`, `ms`, `s`, `m` and `h`.

The `Backup Creation Period` duration indicates at what rate backups should be created. It is not recommended to create backups more often than `30s`.

The `Backup Retention Period` duration indicates at what rate historical backups should be deleted. Backups outside of the retention period are expired after the next successful backup.

The maximum number of backups stored on disk at any given moment follows the equation `ceiling(retention period / creation period)`. For example, `5m` creation period with `4h` retention period would store at most `ceiling(4h / 5m)` backups or `48` backups. A conservative estimate for backup size is `50MB`, so the attached network storage should have at least `2.4GB` free space. Backup sizes will vary depending on usage.

If backups are disabled, the values for `Backup Creation Period` and `Backup Retention Period` are ignored.


### Further Reading

See [the wiki](https://github.com/rancher/rancher/wiki/Kubernetes-Management#deployment-types) for further information regarding usage of this template.
