output "nginx_lb_dns" {
  description = "The DNS name of the NGINX Ingress Load Balancer"
  value       = module.eks-deployment.nginx_lb_dns 
}