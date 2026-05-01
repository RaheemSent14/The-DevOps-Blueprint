
# THE DEVOPS BLUEPRINT: LOCAL TO CLOUD ORCHESTRATION

**Architect:** Raheem Senteza  
**Status:** Phase 1 (Minikube) and Phase 2 (AWS EKS) Verified  

## 1. PROJECT OVERVIEW
This repository documents the evolution of a containerized 2-tier application stack. It serves as a process-oriented blueprint for migrating workloads from a localized development environment (Minikube) to a highly available, managed cloud environment (AWS EKS). The project focuses on Infrastructure-as-Code (IaC), automated CI/CD, and solving the "last mile" challenges of cloud migration.

---

## 2. TECH STACK AND ENGINEERING PRINCIPLES

*   **Orchestration:** Kubernetes (Minikube for Phase 1, AWS EKS v1.31 for Phase 2).
*   **IaC:** Terraform (Modularized for VPC, EKS, and IAM provisioning).
*   **CI/CD:** GitHub Actions (Automated multi-architecture Docker builds and rolling deployments).
*   **Persistence:** Decoupled storage via Persistent Volume Claims (PVC) and AWS EBS CSI Driver.
*   **Security:** Secret abstraction, IAM OIDC provider integration, and non-root security contexts.
*   **Scale:** Horizontally scaled application tier (10 replicas) across multiple Availability Zones.

---

## 3. REPOSITORY STRUCTURE (NAVIGATION GUIDE)

*   **/.github/workflows**: Contains the CI/CD pipeline definitions for automated deployment.
*   **/apps**: Application source code (Flask) and Docker manifests.
*   **/infrastructure/kubernetes**: Kubernetes manifests for compute (Deployments), networking (Services), and storage (PVCs/StorageClasses).
*   **/infrastructure/terraform**: Infrastructure-as-Code definitions used to provision the AWS environment.

---

## 4. SYSTEM ARCHITECTURE EVOLUTION

### PHASE 1: LOCAL ORCHESTRATION (MINIKUBE)

In the initial phase, the priority was defining the application’s logic, containerizing the components, and decoupling the tiers.

```text
                        [ Developer / Localhost ]
                                 |
                                 v
                    +--------------------------+
                    |  Minikube LoadBalancer   |
                    |      (Tunnel/NodePort)   |
                    +------------+-------------+
                                 |
       +-------------------------+-------------------------+
       |                         |                         |
+------v------+           +------v------+           +------v------+
| Flask Pod 1 |    ...    | Flask Pod 5 |    ...    | Flask Pod 10|
+------+------+           +------+------+           +------+------+
                                 |
                    +--------------------------+
                    |      MySQL Service       |
                    +------------+-------------+
                                 |
                    +--------------------------+
                    |   Local Persistent Vol   |
                    +--------------------------+
```

### PHASE 2: PRODUCTION CLOUD (AWS EKS)

The second phase shifted to high availability. The infrastructure was provisioned via Terraform to ensure a repeatable, version-controlled environment in the cloud.

```text
+-----------------+      +----------------------+      +-----------------------------+
|    Developer    |----->|      GitHub Repo     |----->|      GitHub Actions         |
|  (Pushes Code)  |      | (Source Code Mgmt)   |      |   (Multi-Arch Build/Deploy) |
+-----------------+      +----------------------+      +--------------+--------------+
                                                                      |
                                                                      v
                                                       +-----------------------------+
                                                       |        AWS VPC (US-EAST-1)  |
                                                       |  +-----------------------+  |
                                                       |  |  Elastic Load Balancer|  |
                                                       |  +-----------+-----------+  |
                                                       |              |              |
                               +--------------------------------------+--------------+
                               |                                      |
                 +-------------v-------------+          +-------------v-------------+
                 |    EKS Node 1 (AZ-A)      |          |    EKS Node 2 (AZ-B)      |
                 | [t3.small / Managed Grp]  |          | [t3.small / Managed Grp]  |
                 +-------------+-------------+          +-------------+-------------+
                               |                                      |
                               +------------------+-------------------+
                                                  |
                                    +-------------v-------------+
                                    |    AWS EBS (GP2 Volume)   |
                                    |   (StorageClass: ebs-sc)  |
                                    +---------------------------+
```

---

## 5. ARCHITECTURAL DECISION RECORDS (ADR)

### SYSTEM DESIGN THINKING: THE "WHY"

*   **Instance Selection (t3.small):** We utilized T3-series instances for Phase 2. Unlike the T2 generation, T3 instances offer a burstable CPU model with a more consistent baseline performance and support for the Nitro System. This ensures that the EKS Control Plane and the worker nodes maintain low latency during horizontal scaling events.
*   **Subnet Partitioning:** The VPC was architected with subnets spanning multiple Availability Zones. This satisfies the EKS requirement for control plane redundancy and ensures that the application tier remains resilient even if a single AWS data center experiences a service interruption.

### BUSINESS CONTEXT AWARENESS

*   **Cost vs. Performance:** Using t3.small nodes provides a balanced price-to-performance ratio for a portfolio-scale project. It allows for the deployment of a full MySQL instance and a 10-replica Flask tier within a manageable budget, demonstrating the ability to optimize cloud spend while maintaining production-grade metrics.

---

## 6. CASE STUDIES IN TROUBLESHOOTING (RCA)

### CHALLENGE 1: MULTI-ARCHITECTURE CPU COMPATIBILITY

*   **Root Cause Analysis:** Images built on an ARM64 (Apple Silicon) MacBook failed to execute on AMD64 (Intel) EKS worker nodes, resulting in an `Exec format error`.
*   **Engineering Fix:** Integrated **Docker Buildx** into the GitHub Actions pipeline. This enabled cross-platform compilation of the Flask image during the CI phase, ensuring the artifact was native to the target cloud environment (linux/amd64).

### CHALLENGE 2: DYNAMIC STORAGE PROVISIONING

*   **Root Cause Analysis:** The MySQL pod remained in a `Pending` state because modern EKS versions do not natively include the EBS CSI Driver. The Persistent Volume Claim had no provisioner to fulfill the storage request.
*   **Engineering Fix:** Utilized Terraform to install the `aws-ebs-csi-driver` EKS add-on and defined a dedicated **StorageClass** (`ebs.csi.aws.com`). This allowed for automated, dynamic attachment of EBS volumes to the stateful tier.

---

## 7. CODE INTENT AND IMPLEMENTATION

### TERRAFORM: THE ACCESS CONTROL
```hcl
enable_cluster_creator_admin_permissions = true
```
*   **Intent:** This configuration ensures that the IAM identity responsible for provisioning the infrastructure retains administrative access to the Kubernetes API. It resolves the common issue in EKS where the cluster creator is not automatically added to the internal RBAC system.

### KUBERNETES: THE STORAGE CONTRACT
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
```
*   **Intent:** The `WaitForFirstConsumer` binding mode is critical. It tells AWS to wait until the MySQL pod is assigned to a specific node before creating the EBS volume. This prevents "Cross-AZ" errors where a volume is created in a different data center than the pod that needs to mount it.

---

## 8. THE OPERATION: REPRODUCTION STEPS

For junior engineers or contributors looking to replicate this work, follow these steps in order:

1.  **Infrastructure:** Navigate to `/infrastructure/terraform`. Run `terraform init` to initialize the providers, and `terraform apply` to build the AWS network and cluster.

2.  **Authentication:** Update your local `kubeconfig` to talk to the cloud cluster using the AWS CLI:  
    `aws eks update-kubeconfig --region us-east-1 --name raheem-eks-cluster`

3.  **Deployment:** Push your code changes to the `main` branch. GitHub Actions will automatically detect the push, build the AMD64-compatible image, and update the EKS deployment.

4.  **Verification:** Run `kubectl get svc` to find the **EXTERNAL-IP** of the `raheem-web-service`. Paste that DNS address into your browser to see the live application.

---

## 9. ENGINEERING RETROSPECTIVE

This project successfully demonstrated the transition from a local development workflow to a production cloud environment. By addressing challenges in CPU architecture parity, dynamic storage provisioning, and IaC modularity, this blueprint provides a resilient foundation for containerized microservices. The project highlights a deep understanding of environment portability and automated lifecycle management.