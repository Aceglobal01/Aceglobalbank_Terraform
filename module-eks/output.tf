output "nginx_lb_dns" {
  description = "The DNS name of the NGINX Ingress Load Balancer"
  value       = try(data.kubernetes_service.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname, null)
}