resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.1"

  depends_on = [module.eks]
}

resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.10.1"

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  depends_on = [module.eks]
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  version          = "0.9.19"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.eso_irsa.iam_role_arn
  }

  depends_on = [module.eks, module.eso_irsa]
}

resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  namespace        = "keda"
  create_namespace = true
  version          = "2.14.0"

  # KEDA usa o instance profile do nó (node_aws_services policy)
  # para ler a profundidade da fila SQS — sem IRSA, sem credenciais no cluster.

  depends_on = [module.eks]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "6.7.3"

  # --insecure desativa TLS no servidor interno — o Ingress ou LoadBalancer faz o TLS.
  # type: LoadBalancer expõe o argocd-server diretamente para acesso via browser.
  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  depends_on = [module.eks]
}
