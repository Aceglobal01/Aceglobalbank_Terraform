terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24.0"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

provider "kubernetes" {
  alias                  = "eks"
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress-v2"
  namespace        = "ingress-nginx-v2"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.12.0"
  create_namespace = true
  timeout          = 900
  
  force_update     = true
  recreate_pods    = true

  set {
    name  = "controller.admissionWebhooks.enabled"
    value = "false"
  }

  set {
    name  = "controller.replicaCount"
    value = "1"
  }
  set {
    name  = "controller.resources.requests.cpu"
    value = "50m"
  }
  set {
    name  = "controller.resources.requests.memory"
    value = "50Mi"
  }

  values     = [file("${path.module}/nginx-ingress-values.yaml")]
  depends_on = [aws_eks_node_group.eks_node_group]
}

resource "time_sleep" "wait_for_ingress_lb" {
  depends_on      = [helm_release.nginx_ingress]
  create_duration = "3m"
}

# ==================================================
# THE FIXES ARE APPLIED HERE
# ==================================================

data "kubernetes_service" "ingress_nginx" {
  metadata {
    # The name Helm typically assigns to the controller service 
    name      = "nginx-ingress-v2-ingress-nginx-controller" 
    # Must match the helm_release namespace exactly
    namespace = "ingress-nginx-v2" 
  }
  # Wait for the sleep timer to finish so AWS actually provisions the LB
  depends_on = [time_sleep.wait_for_ingress_lb] 
}


# ==================================================

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.14.5"
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [helm_release.nginx_ingress]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.51.6"
  namespace        = "argocd"
  create_namespace = true
  values           = [file("${path.module}/argocd-values.yaml")]
  depends_on       = [helm_release.nginx_ingress, helm_release.cert_manager]
}