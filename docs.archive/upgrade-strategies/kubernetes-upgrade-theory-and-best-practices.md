# Kubernetes Upgrade Strategy and Technical Procedures: From Theoretical Foundation to Safe Enterprise Implementation

## Overview

In the rapidly evolving cloud-native ecosystem, maintaining a Kubernetes cluster at the latest version is not only a feature requirement but also a cornerstone of security strategy and sustainable infrastructure operations. Kubernetes, with its three minor releases per year, demands a strict lifecycle management process where errors in the upgrade process can lead to widespread service disruption or cluster state data loss.

To successfully execute this process in highly complex environments, operators need deep understanding of version skew policies, workload protection mechanisms like Pod Disruption Budgets (PDB), and core infrastructure changes such as transitioning package repositories to community-owned systems.

## Theoretical Foundation and Version Skew Policy

The theoretical basis of Kubernetes upgrade procedures lies in the Version Skew Policy, a set of rules that determine compatibility between different system components when they run at different versions. This policy ensures that communication between components (such as API server and Kubelet) remains stable throughout the upgrade transition period.

### Semantic Versioning Rules and Release Cycles

Kubernetes applies Semantic Versioning with the format x.y.z, where x represents the major version, y is the minor version, and z is the patch version. In practice, the Kubernetes project currently maintains support for the three most recent minor versions, such as 1.35, 1.34, and 1.33 as of 2025.

Each minor version after release receives security patches and critical bug fixes for approximately twelve months.

**Critical Principle**: System architects must never perform skip-level upgrades across minor versions. For example, upgrading directly from 1.33 to 1.35 is unsupported and carries high risk of breaking Custom Resource Definitions (CRDs) or corrupting etcd storage structure. Instead, the system must be upgraded sequentially from 1.33 to 1.34, then from 1.34 to 1.35.

Conversely, patch version upgrades within the same minor line (e.g., from 1.34.1 to 1.34.2) can be performed directly without sequence restrictions.

### Component Compatibility Matrix

Kube-apiserver serves as the central "anchor" for the entire cluster, and its version determines version limits for all other components. Understanding this matrix helps prevent unwanted API communication errors that typically arise when an outdated component attempts to interact with a newer API server.

| **Component** | **Relationship with Kube-apiserver** | **Version Skew Limit** |
|---------------|--------------------------------------|-------------------------|
| **Kube-apiserver (HA)** | Between apiserver instances | Maximum 1 minor version (e.g., one instance runs 1.34, another runs 1.35) |
| **Kubelet** | Kubelet vs API server | Can be up to 3 minor versions older but not newer than API server |
| **Kube-proxy** | Kube-proxy vs API server | Can be up to 3 minor versions older but not newer than API server |
| **Controller Manager** | Controller Manager vs API server | Maximum 1 minor version older, cannot be newer |
| **Scheduler** | Scheduler vs API server | Maximum 1 minor version older, cannot be newer |
| **Kubectl** | Client vs API server | Maximum +/- 1 minor version |

The relaxed limit for Kubelet (up to 3 minor versions) is an intentional design to allow administrators sufficient time to upgrade thousands of worker nodes without disrupting the cluster's shared infrastructure. However, for kube-controller-manager and kube-scheduler, near-absolute synchronization is mandatory as these components depend closely on API server data structures to execute control logic and scheduling.

## Package Infrastructure Management and Migration to pkgs.k8s.io

A pivotal change in Kubernetes management since late 2023 is the discontinuation of old Google-hosted package repositories (apt.kubernetes.io and yum.kubernetes.io) in favor of community-owned infrastructure at pkgs.k8s.io. Overlooking this change is the leading cause of upgrade preparation failures, when package management systems cannot find new versions of kubeadm or kubelet.

### New Package System Mechanism

The pkgs.k8s.io infrastructure uses SUSE's OpenBuildService (OBS) platform, enabling more transparent package building processes and supporting diverse hardware architectures including AMD64, ARM64, PPC64LE, and S390X.

The biggest technical difference is that each Kubernetes minor version is now separated into its own repository branch. This means when operators prepare to upgrade from v1.34 to v1.35, they must update the OS source configuration file (e.g., `/etc/apt/sources.list.d/kubernetes.list`) to point to the v1.35 version URL before executing installation commands.

This process ensures stability by preventing accidental upgrades to unwanted minor versions during routine OS update cycles. Migration to the new repository requires not only URL changes but also updating new GPG signing keys to ensure authenticity of downloaded software packages.

## Backup Strategy and etcd Data Protection

Before implementing any changes to the Control Plane, establishing a reliable recovery point for etcd — the "brain" storing all cluster state and configuration — is a mandatory prerequisite. Although kubeadm performs static manifest backups to `/etc/kubernetes/tmp`, it cannot automatically salvage an etcd database corrupted during schema transitions.

### Advanced etcd Snapshot Procedures

etcd backup must be performed through the etcdctl tool with API version v3. For kubeadm-initialized clusters, etcd typically runs as a static pod with security certificates located at `/etc/kubernetes/pki/etcd/`. A standard backup command must specify endpoints and certificate files for access authentication:

```bash
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /backup/etcd-snapshot-$(date +%Y-%m-%d).db
```

After creating the snapshot, the most critical step often overlooked by administrators is verifying file integrity using etcdutl (introduced to replace non-operational functions of etcdctl from v3.5). The `etcdutl snapshot status` command displays a data table including Hash, Revision, and Total Keys. If these values display correctly, the backup is considered ready for emergency situations.

### Disaster Recovery Scenarios

In cases where the upgrade process causes irreversible etcd corruption, the recovery process requires stopping all kube-apiserver instances across all Control Plane nodes to prevent attempts to write new data to an inconsistent state. Data is then restored to a new directory (e.g., `/var/lib/etcd-new`), and static manifests at `/etc/kubernetes/manifests/etcd.yaml` must be manually updated to point hostPath to this new directory.

System restart must then follow sequence: etcd first, then Control Plane components.

## Safe Control Plane Upgrade Execution

Control Plane upgrade is the most sensitive phase, where central management components are replaced with newer versions. Kubeadm divides this process into two main phases: upgrading the orchestration tool (kubeadm) and then upgrading execution components (apiserver, controller-manager, scheduler).

### Phase 1: Upgrading the First Control Plane Node (Primary)

On the node serving the primary role (typically the node containing admin.conf), administrators begin by updating the kubeadm package. Using `apt-mark unhold` and `hold` is necessary to maintain absolute control over software versions throughout the cluster lifecycle.

The `kubeadm upgrade plan` command is a critical defense mechanism. It not only lists available versions but also performs cluster health checks, ensuring all current nodes are in Ready state and the API server can respond. If any abnormalities are detected regarding expiring certificates, kubeadm will notify and by default automatically renew them during the upgrade process.

## Best Practices and Safety Guidelines

### Pre-Upgrade Checklist
- ✅ Backup etcd with verified integrity
- ✅ Check cluster health with `kubeadm upgrade plan`
- ✅ Update package repositories to pkgs.k8s.io
- ✅ Verify version skew policy compliance
- ✅ Use `apt-mark hold/unhold` for version control

### Critical Safety Rules
1. **Never skip minor versions** - Always upgrade sequentially
2. **Always backup etcd first** - No exceptions
3. **Verify component compatibility** - Check version skew matrix
4. **Test in staging environment** - Before production upgrades
5. **Monitor cluster health** - Throughout the process

### Emergency Procedures
- Keep etcd snapshots for quick rollback
- Document rollback procedures
- Maintain communication channels during upgrades
- Have disaster recovery plan ready

## Conclusion

Kubernetes upgrade procedures require meticulous planning, deep understanding of component interactions, and strict adherence to safety protocols. The combination of theoretical knowledge about version skew policies, practical backup strategies, and systematic execution ensures successful upgrades in enterprise environments while minimizing risks to production workloads.