# ToggleMaster - Fase 3: CI/CD + GitOps

**FIAP POSTECH - DevOps e Arquitetura Cloud**
**RM 373161 - Lucas Santana Bezerra de Melo**

Fase 3 do Tech Challenge. Implementação de pipelines CI/CD com DevSecOps e GitOps com ArgoCD para os cinco microsserviços da plataforma de feature flags ToggleMaster.

---

## Arquitetura

```
GitHub Push
    |
    v
+---------------------------------------------+
|          GitHub Actions (CI)                |
|  build-test --+-- lint          (paralelo)  |
|               +-- security (Trivy + SAST)   |
|                        |                    |
|               docker-push --> ECR (main only)|
|                        |                    |
|          atualiza deployment.yaml (gitops)  |
+---------------------------------------------+
    |
    v  (GitOps)
+---------------------------------------------+
|              ArgoCD (EKS)                   |
|   detecta mudança no deployment.yaml        |
|   sincroniza automaticamente no cluster     |
+---------------------------------------------+
    |
    v
+---------------------------------------------+
|        Kubernetes - namespace togglemaster  |
|  auth  flag  targeting  analytics  evaluation|
+---------------------------------------------+
```

---

## Microsserviços

| Servico | Linguagem | Porta | Banco |
|---|---|---|---|
| auth-service | Go | 8001 | RDS PostgreSQL |
| flag-service | Python | 8002 | RDS PostgreSQL |
| targeting-service | Python | 8003 | RDS PostgreSQL |
| evaluation-service | Go | 8004 | ElastiCache Redis + SQS |
| analytics-service | Python | 8005 | DynamoDB + SQS |

---

## Estrutura do repositório

```
.
+-- .github/workflows/          # Pipelines CI/CD (um por servico)
|   +-- ci-auth-service.yml
|   +-- ci-flag-service.yml
|   +-- ci-targeting-service.yml
|   +-- ci-analytics-service.yml
|   +-- ci-evaluation-service.yml
|   +-- terraform.yml           # Plan / Apply
|   +-- terraform-destroy.yml   # Destroy com confirmacao manual
|
+-- services/                   # Codigo-fonte dos microsservicos
|   +-- auth-service/
|   +-- flag-service/
|   +-- targeting-service/
|   +-- analytics-service/
|   +-- evaluation-service/
|
+-- gitops/                     # Manifestos Kubernetes (fonte de verdade do ArgoCD)
|   +-- auth-service/
|   +-- flag-service/
|   +-- targeting-service/
|   +-- analytics-service/
|   +-- evaluation-service/
|
+-- infra/terraform/            # Infraestrutura como codigo (AWS)
    +-- backend.tf              # State remoto - S3
    +-- main.tf
    +-- eks.tf
    +-- vpc.tf
    +-- rds.tf
    +-- elasticache.tf
    +-- ecr.tf
    +-- messaging.tf            # SQS + DynamoDB
    +-- helm-addons.tf          # ArgoCD, ESO, KEDA via Helm
    +-- argocd-app.tf           # ApplicationSet ArgoCD
    +-- iam-eso.tf              # IRSA para External Secrets Operator
    +-- iam-keda.tf             # IRSA para KEDA
    +-- variables.tf
```

---

## Pipeline CI/CD

Cada push em qualquer branch dispara os tres primeiros jobs. O `docker-push` so executa em merge para `main`.

```
build-test --+-- lint      (paralelo)
             +-- security  (paralelo)
                    |
               docker-push  (main only)
                    |
             atualiza gitops manifest
```

### Jobs

**`build-test`**
- Go: `go mod tidy` + `go build` + `go test ./...`
- Python: `pip install` + `pytest`

**`lint`**
- Go: `go vet ./...`
- Python: `flake8`

**`security`**
- Trivy (filesystem) - bloqueia CVEs CRITICAL e HIGH (`exit-code: 1`)
- Go: `gosec`
- Python: `bandit`

**`docker-push`**
- Build da imagem Docker
- Trivy container scan - bloqueia CVEs CRITICAL e HIGH antes do push
- Push para Amazon ECR com tag `sha-<7chars>`
- Atualiza `gitops/<servico>/deployment.yaml` com a nova tag
- Commit com sufixo `[skip ci]` para evitar loop

### Autenticacao AWS

O pipeline usa GitHub OIDC (sem credenciais estaticas armazenadas).
Role: `CICD-terraform-infra` com permissoes para ECR e EKS.

---

## GitOps - ArgoCD

O ArgoCD monitora a pasta `gitops/` com `directory.recurse: true`. Quando o pipeline atualiza a tag da imagem no `deployment.yaml`, o ArgoCD detecta a divergencia e sincroniza automaticamente (auto-sync + prune + selfHeal).

```
Codigo --> CI build --> ECR image (sha-abc1234)
                    --> gitops/auth-service/deployment.yaml atualizado
                              |
                         ArgoCD detecta
                              |
                    kubectl apply no cluster EKS
```

---

## Infraestrutura (Terraform)

**Recursos criados**

| Recurso | Configuracao |
|---|---|
| VPC | 2 subnets publicas + 2 privadas, NAT Gateway |
| EKS | Cluster 1.36 + 2x t3.medium (managed node group) |
| RDS PostgreSQL | 3x db.t3.micro Single-AZ, 20 GB, criptografado |
| ElastiCache | 1x cache.t3.micro Redis com TLS |
| ECR | 5 repositorios (um por servico) |
| SQS | Fila criptografada com KMS para analytics |
| DynamoDB | Tabela on-demand para analytics |
| Secrets Manager | Segredos por servico (credenciais de banco) |
| S3 | Bucket de state do Terraform (versionado, criptografado) |

**Provisionar**

```bash
cd infra/terraform
terraform init
terraform plan
terraform apply
```

**Configurar kubectl**

```bash
aws eks update-kubeconfig --name togglemaster --region us-east-1
kubectl get nodes
```

**Destruir**

```bash
# Via GitHub Actions (recomendado)
# Actions --> Terraform Destroy --> Run workflow --> digite DESTROY

# Ou localmente
terraform destroy
```

> Destrua imediatamente apos a avaliacao. Custo estimado: ~$250/mes se mantido 24/7.

---

## DevSecOps

O pipeline bloqueia automaticamente antes do push para o ECR qualquer imagem com CVE CRITICAL ou HIGH. Credenciais nunca sao commitadas - todas as senhas trafegam via AWS Secrets Manager -> External Secrets Operator -> Kubernetes Secret.
