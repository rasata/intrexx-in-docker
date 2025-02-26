# Deploying Intrexx Applications to Kubernetes

This document outlines how to deploy Intrexx applications to Kubernetes using Helm charts with auto load balancing.

## Prerequisites

- Kubernetes cluster (v1.19+)
- Helm 3.0+
- kubectl configured to communicate with your cluster
- Container registry access for Intrexx images

## Architecture Overview

The Kubernetes deployment consists of the following components:

1. **Intrexx Portal Pods**: Stateless application servers running the Intrexx portal
2. **PostgreSQL Database**: Persistent storage for Intrexx data
3. **Solr Search**: Search engine for Intrexx applications
4. **Zookeeper**: Coordination service for Solr
5. **Ingress Controller**: For load balancing and routing external traffic

## Deployment Steps

### 1. Add the Intrexx Helm Repository

```bash
helm repo add intrexx-charts https://your-helm-repo-url
helm repo update
```

### 2. Configure Values

Create a custom `values.yaml` file to override default settings:

```yaml
# Example values.yaml
replicaCount: 3  # Number of Intrexx portal instances

image:
  repository: unitedplanet/intrexx
  tag: latest
  pullPolicy: IfNotPresent

ingress:
  enabled: true
  className: nginx
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
  hosts:
    - host: intrexx.example.com
      paths:
        - path: /
          pathType: Prefix

persistence:
  enabled: true
  storageClass: "standard"
  size: 10Gi

database:
  type: postgresql
  host: intrexx-postgresql
  name: intrexx
  user: postgres
  password: postgres

solr:
  enabled: true
  replicas: 2
  
zookeeper:
  enabled: true
  replicas: 3
```

### 3. Install the Helm Chart

```bash
helm install intrexx-portal intrexx-charts/intrexx-portal -f values.yaml -n intrexx --create-namespace
```

### 4. Verify the Deployment

```bash
kubectl get pods -n intrexx
kubectl get svc -n intrexx
kubectl get ingress -n intrexx
```

## Auto Scaling

The Intrexx portal deployment supports Horizontal Pod Autoscaling (HPA) for automatically scaling based on CPU/memory usage:

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80
```

## Load Balancing

Load balancing is handled at two levels:

1. **Service Level**: Kubernetes Service distributes traffic among Intrexx pods
2. **Ingress Level**: Ingress controller routes external traffic to the service

## Monitoring and Logging

The Helm chart includes Prometheus exporters and supports integration with:

- Prometheus for metrics collection
- Grafana for visualization
- ELK stack for log aggregation

## Backup and Disaster Recovery

Regular backups of the following components are recommended:

- PostgreSQL database
- Solr indices
- Zookeeper data
- Persistent volumes containing Intrexx configuration

## Upgrading

To upgrade your Intrexx deployment:

```bash
helm upgrade intrexx-portal intrexx-charts/intrexx-portal -f values.yaml -n intrexx
```

## Troubleshooting

Common issues and their solutions:

1. **Database connection issues**: Verify database credentials and network policies
2. **Solr connectivity**: Check Zookeeper connection and Solr configuration
3. **Pod scheduling failures**: Check resource constraints and node capacity

For more detailed troubleshooting, check the logs:

```bash
kubectl logs -n intrexx -l app=intrexx-portal
```
