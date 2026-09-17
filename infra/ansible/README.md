# infra/ansible/

Configuration *inside* machines that already exist, and the tier 3 deployment.

The boundary with the other tools (ADR-0014): OpenTofu creates the machine,
Ansible configures what is in it, Argo CD owns what runs inside the tier 4
cluster. Ansible never creates cloud resources and never applies Kubernetes
manifests.

> **Nothing here has been run yet.** There is no host wired up.

| Playbook | What it does |
|---|---|
| `deploy-staging.yml` | Tier 3 deployment. Reaches the host, syncs files, runs `scripts/deploy-staging.sh` |
| `migrate-staging.yml` | Migration against tier 3, in either direction, recorded on the host |
| `node-add.yml` | Joins a worker to a **self-managed** cluster |
| `node-remove.yml` | Drains a node and removes it from the cluster |

```bash
cd infra/ansible
cp inventory/hosts.yml.example inventory/hosts.yml   # not committed
ansible-playbook deploy-staging.yml -e kaiju_image=ghcr.io/OWNER/kaiju/backend:sha-abc1234
```

---

## Two things worth knowing before running any of it

### `deploy-staging.yml` does not contain the deployment order

It runs `scripts/deploy-staging.sh`, and that script is the only place the order
`migration → worker and scheduler → api and realtime` is written down. The order
is mandatory (CON-69); a second copy of it is a second copy that drifts.

### `node-remove.yml` stops one step short, on purpose

It drains the node and deletes it from the cluster. It does **not** destroy the
machine — that is `tofu destroy`, run separately. Destroying the machine first
kills its pods abruptly, which the application survives but realtime clients
feel as a stream dropped without a graceful close.

If the drain hangs, it is almost always two replicas of one role sitting on that
node, with the disruption budget correctly refusing to evict the last one. That
is what the replica spread constraints exist to prevent (CON-79).

---

## Managed clusters do not use the node playbooks

On a managed cluster the node pool is an OpenTofu variable and the cluster
autoscaler adds nodes when pods are Pending. `node-add.yml` and `node-remove.yml`
are for a self-managed cluster only.
