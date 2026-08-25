# ── ArgoCD Application — aponta para a pasta gitops/ do monorepo ─────────────
# O ArgoCD monitora todos os manifests em gitops/ e aplica automaticamente
# qualquer mudança commitada no branch main (auto-sync + prune + selfHeal).

resource "kubectl_manifest" "argocd_app" {
  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: togglemaster
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: https://github.com/${var.github_repo}
        targetRevision: main
        path: gitops
        directory:
          recurse: true
      destination:
        server: https://kubernetes.default.svc
        namespace: togglemaster
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
  YAML

  depends_on = [helm_release.argocd]
}

output "argocd_server_url" {
  description = "Após o apply, obtenha o IP com: kubectl get svc argocd-server -n argocd"
  value       = "kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "argocd_initial_password_cmd" {
  description = "Senha inicial do admin do ArgoCD"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}
