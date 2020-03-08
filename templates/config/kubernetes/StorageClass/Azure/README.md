# Azure File Kubernetes Storage Driver

## Storage Classes

| Name                              | Driver                     | Type         | Replication | Retention Policy | Cache    |
| --------------------------------- | -------------------------- | ------------ | ----------- | ---------------- | -------- |
| `managed-premium-grs-retain`      | `kubernetes.io/azure-disk` | Premium SSD  | GRS         | Retain           | ReadOnly |
| `managed-premium-grs-delete`      | `kubernetes.io/azure-disk` | Premium SSD  | GRS         | Delete           | ReadOnly |
| `managed-premium-lrs-retain`      | `kubernetes.io/azure-disk` | Premium SSD  | LRS         | Retain           | ReadOnly |
| `managed-premium-lrs-delete`      | `kubernetes.io/azure-disk` | Premium SSD  | LRS         | Delete           | ReadOnly |
| `managed-standard-grs-retain`     | `kubernetes.io/azure-disk` | Standard HDD | GRS         | Retain           | ReadOnly |
| `managed-standard-grs-delete`     | `kubernetes.io/azure-disk` | Standard HDD | GRS         | Delete           | ReadOnly |
| `managed-standard-lrs-retain`     | `kubernetes.io/azure-disk` | Standard HDD | LRS         | Retain           | ReadOnly |
| `managed-standard-lrs-delete`     | `kubernetes.io/azure-disk` | Standard HDD | LRS         | Delete           | ReadOnly |
| `azurefile-premium-grs-delete`    | `kubernetes.io/azure-file` | Premium SSD  | GRS         | Delete           | N/A      |
| `azurefile-premium-lrs-delete`    | `kubernetes.io/azure-file` | Premium SSD  | LRS         | Delete           | N/A      |
| `azurefile-standard-grs-delete`   | `kubernetes.io/azure-file` | Standard HDD | GRS         | Delete           | N/A      |
| `azurefile-standard-lrs-delete`   | `kubernetes.io/azure-file` | Standard HDD | LRS         | Delete           | N/A      |
| `azurefile-standard-zrs-delete`   | `kubernetes.io/azure-file` | Standard HDD | ZRS         | Delete           | N/A      |
| `azurefile-standard-ragrs-delete` | `kubernetes.io/azure-file` | Standard HDD | RAGRS       | Delete           | N/A      |
