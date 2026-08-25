# Setup — ToggleMaster Fase 3

## 1. Pré-requisitos

- AWS CLI configurado (`aws configure`)
- Terraform >= 1.5
- kubectl
- Docker

## 2. Criar o bucket S3 para o Terraform state (único passo manual)

```bash
aws s3 mb s3://togglemaster-tfstate --region us-east-1
aws s3api put-bucket-versioning \
  --bucket togglemaster-tfstate \
  --versioning-configuration Status=Enabled
```

## 3. Configurar GitHub Secrets

No repositório https://github.com/lcsbm/togglemaster-fase3, vá em:
**Settings → Secrets and variables → Actions → New repository secret**

| Secret | Valor |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | Chave de acesso IAM com permissões ECR + EKS |
| `AWS_SECRET_ACCESS_KEY` | Chave secreta correspondente |

> **Nunca salve as chaves da AWS no código ou em arquivos versionados.**

## 4. Criar infraestrutura com Terraform

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# Edite terraform.tfvars se necessário

terraform init
terraform plan
terraform apply
```

O `apply` cria:
- VPC + subnets + NAT Gateway
- EKS 1.36 (t3.medium, 2 nós)
- 3× RDS PostgreSQL 15
- ElastiCache Redis
- SQS + DynamoDB
- 5× ECR repositories
- IAM roles (ESO IRSA, KEDA)
- Helm releases: metrics-server, ingress-nginx, external-secrets, keda, **argocd**
- ArgoCD Application apontando para `gitops/`

## 5. Configurar kubectl

```bash
aws eks update-kubeconfig --name togglemaster --region us-east-1
```

## 6. Obter acesso ao ArgoCD

```bash
# IP/hostname do ArgoCD
kubectl get svc argocd-server -n argocd

# Senha inicial do admin
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```

## 7. Pipeline CI/CD

Ao fazer push para `main` em qualquer serviço (`services/<name>/`):

1. **build-test** — compila/testa o serviço
2. **lint** (paralelo) — golangci-lint ou flake8
3. **security** (paralelo) — Trivy SCA + gosec/bandit
4. **docker-push** — build, Trivy container scan, push para ECR
5. CI atualiza `gitops/<name>/deployment.yaml` com a nova tag `sha-<commit>`
6. ArgoCD detecta o commit e sincroniza o cluster automaticamente

## 8. Demonstrar pipeline falhando (Trivy)

```bash
# Inserir versão vulnerável no requirements.txt de qualquer serviço Python
# Ex: requests==2.6.0  (CVE conhecida)
# Fazer commit → Trivy SCA detecta CRITICAL → job security falha → docker-push não roda
# Corrigir a versão → pipeline passa → ArgoCD sincroniza nova imagem
```
