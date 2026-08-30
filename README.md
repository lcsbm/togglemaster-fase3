# ToggleMaster — Fase 3: CI/CD + GitOps

**FIAP POSTECH — DevOps e Arquitetura Cloud**  
**Aluno:** Lucas Santana Bezerra de Melo | **RM:** 373161

Fase 3 do Tech Challenge. Implementação de pipelines CI/CD com DevSecOps e GitOps com ArgoCD para os cinco microserviços da plataforma de feature flags ToggleMaster.

---

## Arquitetura

```
  GitHub Push
      │
      ▼
┌─────────────────────────────────────────────┐
│           GitHub Actions (CI)               │
│  build-test ──┬── lint          (paralelo)  │
│               └── security (Trivy + SAST)   │
│                        │                    │
│               docker-push → ECR  (main only)│
│                        │                    │
│          sed deployment.yaml + git push      │
└─────────────────────────────────────────────┘
      │
      ▼  (GitOps)
┌─────────────────────────────────────────────┐
│              ArgoCD (EKS)                   │
│   detecta mudança no deployment.yaml        │
│   sincroniza automaticamente no cluster     │
└─────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────┐
│         Kubernetes — namespace togglemaster  │
│  auth  flag  targeting  analytics  evaluation│
└─────────────────────────────────────────────┘
```

---

## Microserviços

| Serviço | Linguagem | Porta | Banco |
|---|---|---|---|
| auth-service | Go | 8001 | RDS PostgreSQL |
| flag-service | Go | 8000 | RDS PostgreSQL |
| targeting-service | Python | 8003 | RDS PostgreSQL |
| analytics-service | Python | 8005 | DynamoDB + SQS |
| evaluation-service | Go | 8004 | ElastiCache Redis |

---

## Estrutura do Repositório

```
.
├── .github/workflows/          # Pipelines CI/CD (um por serviço)
│   ├── ci-auth-service.yml
│   ├── ci-flag-service.yml
│   ├── ci-targeting-service.yml
│   ├── ci-analytics-service.yml
│   └── ci-evaluation-service.yml
│
├── services/                   # Código-fonte dos microserviços
│   ├── auth-service/
│   ├── flag-service/
│   ├── targeting-service/
│   ├── analytics-service/
│   └── evaluation-service/
│
├── gitops/                     # Manifestos Kubernetes (fonte de verdade do ArgoCD)
│   ├── auth-service/
│   ├── flag-service/
│   ├── targeting-service/
│   ├── analytics-service/
│   └── evaluation-service/
│
└── infra/terraform/            # Infraestrutura como código (AWS)
    ├── backend.tf              # State remoto — S3
    ├── main.tf
    ├── eks.tf
    ├── vpc.tf
    ├── rds.tf
    ├── elasticache.tf
    ├── ecr.tf
    ├── messaging.tf            # SQS + DynamoDB
    ├── helm-addons.tf          # ArgoCD, ESO, KEDA via Helm
    ├── argocd-app.tf           # ApplicationSet ArgoCD
    ├── iam-eso.tf              # IRSA para External Secrets Operator
    └── variables.tf
```

---

## Pipeline CI/CD

Cada push em qualquer branch dispara os três primeiros jobs. O `docker-push` só executa em merge para `main`.

```
build-test ──┬── lint      (paralelo)
             └── security  (paralelo)
                    │
               docker-push  (main only)
                    │
             update gitops manifest
```

### Jobs

**`build-test`**
- Go: `go mod tidy` + `go build` + `go test ./...`
- Python: `pip install` + `pytest`

**`lint`**
- Go: `golangci-lint run`
- Python: `flake8`

**`security`**
- Trivy (modo filesystem) — bloqueia CVEs **CRITICAL** (`exit-code: 1`)
- Go: `gosec ./...`
- Python: `bandit -r .`

**`docker-push`**
- Build da imagem Docker
- Push para Amazon ECR com tag `sha-<7chars>`
- Atualiza `gitops/<serviço>/deployment.yaml` com a nova tag via `sed`
- Commit com sufixo `[skip ci]` para evitar loop

### Segredos necessários no repositório

| Secret | Descrição |
|---|---|
| `AWS_ACCESS_KEY_ID` | Credencial AWS para push no ECR |
| `AWS_SECRET_ACCESS_KEY` | Credencial AWS para push no ECR |
| `GH_TOKEN` | Token com permissão de escrita para o gitops commit |

> Credenciais nunca são commitadas. Todas as senhas de banco de dados em produção trafegam via AWS Secrets Manager → External Secrets Operator → Kubernetes Secret.

---

## GitOps — ArgoCD

O ArgoCD monitora a pasta `gitops/` com `directory.recurse: true`. Quando o pipeline atualiza a tag da imagem no `deployment.yaml`, o ArgoCD detecta a divergência e sincroniza automaticamente (auto-sync + prune + selfHeal).

```
Código  →  CI build  →  ECR image (sha-abc1234)
                    →  gitops/auth-service/deployment.yaml atualizado
                              ↓
                         ArgoCD detecta
                              ↓
                    kubectl apply no cluster EKS
```

---

## Infraestrutura (Terraform)

**Pré-requisitos**
- AWS CLI configurado (`aws configure`)
- Terraform >= 1.10
- kubectl

**Provisionar**

```bash
cd infra/terraform

# 1. Inicializar (conecta ao backend S3)
terraform init

# 2. Verificar o plan
terraform plan -var-file="terraform.tfvars"

# 3. Aplicar (~15 min)
terraform apply -var-file="terraform.tfvars"

# 4. Configurar kubectl
aws eks update-kubeconfig --name togglemaster --region us-east-1
```

**terraform.tfvars** (não versionado — crie localmente)

```hcl
aws_region        = "us-east-1"
project           = "togglemaster"
eks_node_type     = "t3.medium"
eks_desired_nodes = 2
github_repo       = "lcsbm/togglemaster-fase3"
```

**Recursos criados**

| Recurso | Configuração |
|---|---|
| VPC | 3 subnets públicas + 3 privadas |
| EKS | Cluster + 2× t3.medium (managed node group) |
| RDS PostgreSQL | 3× db.t3.micro Single-AZ, 20 GB |
| ElastiCache | 1× cache.t3.micro Redis OSS |
| ECR | 5 repositórios (um por serviço) |
| SQS | Fila padrão para analytics |
| DynamoDB | Tabela on-demand para analytics |
| Secrets Manager | 8 segredos (credenciais de banco) |
| S3 | Bucket de state do Terraform (versionado) |

**Destruir**

```bash
terraform destroy -var-file="terraform.tfvars"
```

> Destrua imediatamente após a avaliação. Custo estimado: **$248,71/mês** se mantido 24/7 ([ver estimativa completa](https://calculator.aws/#/estimate?id=d21f4aa5c2c994b32ea25a93f43c9daf290354de)).

---

## DevSecOps — CVEs corrigidas

| CVE | Severidade | Componente | Correção |
|---|---|---|---|
| CVE-2025-68121 | CRITICAL | Go 1.21 crypto/tls | Upgrade para `golang:1.25-alpine` |
| CVE-2026-13221 | CRITICAL | perl-base (Debian) | Migração para `python:3.11-alpine` |
| CVE-2026-42496 | CRITICAL | perl-base (Debian) | Migração para `python:3.11-alpine` |
| CVE-2026-8376 | CRITICAL | perl-base (Debian) | Migração para `python:3.11-alpine` |

O pipeline bloqueia automaticamente qualquer imagem com CVE CRITICAL antes do push para o ECR.
