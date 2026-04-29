
#  The DevOps Blueprint

**Architect:** Raheem Senteza

**Status:** Phase 1 (Local Orchestration) Complete | Phase 2 (AWS EKS) In-Progress

A process-oriented blueprint for deploying highly available, containerized microservices. This repository serves as a modular foundation for moving from local development to production-grade cloud infrastructure.

##  System Architecture (Local Environment)

This architecture utilizes Kubernetes to manage a decoupled 2-tier application stack.
```text
                        [ User / Internet ]
                                 |
                                 v
                    +--------------------------+
                    |  LoadBalancer Service    |
                    |      (Port 80)           |
                    +------------+-------------+
                                 |
       +-------------------------+-------------------------+
       |                         |                         |
+------v------+           +------v------+           +------v------+
| Flask Pod 1 |    ...    | Flask Pod 5 |    ...    | Flask Pod 10|
| (Port 5000) |           | (Port 5000) |           | (Port 5000) |
+------+------+           +------+------+           +------+------+
                                 |
                    +--------------------------+
                    |      MySQL Service       |
                    |       (Headless)         |
                    +------------+-------------+
                                 |
                    +--------------------------+
                    |        MySQL Pod         |
                    | (Persistent Storage/PVC) |
                    +--------------------------+
```

##   Tech Stack & Engineering Principles

*   **Orchestration:** Kubernetes (Minikube)
*   **IaC:** Terraform (Modularized for AWS expansion)
*   **Persistence:** Decoupled storage via Persistent Volume Claims (PVC)
*   **Security:** Secret abstraction and non-root security contexts
*   **Scale:** Horizontally scaled application tier (10 replicas)

##   Repository Structure

*   `/apps`: Application source code and Docker manifests.
*   `/infrastructure/kubernetes`: K8s manifests for compute, networking, and storage.
*   `/infrastructure/terraform`: Infrastructure-as-Code definitions (Project 2 baseline).
```
