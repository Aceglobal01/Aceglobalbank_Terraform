output "nginx_lb_dns" {
  description = "The DNS name of the NGINX Ingress Load Balancer"
  value       = try(data.kubernetes_service.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname, null)
}

output "nginx_lb_ip" {
  description = "Fallback for IP if hostname isn't used"
  value       = try(data.kubernetes_service.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname, null)
}

output "nginx_ingress_load_balancer_hostname" {
  description = "Redundant output for Namecheap module"
  value       = try(data.kubernetes_service.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname, null)
}