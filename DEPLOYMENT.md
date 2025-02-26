# Deploying Intrexx Applications to Kubernetes

This document outlines how to deploy Intrexx applications to Kubernetes using Helm charts with auto load balancing. It covers both platform-level operations and individual application management.

## Prerequisites

- Kubernetes cluster (v1.19+)
- Helm 3.0+
- kubectl configured to communicate with your cluster
- Container registry access for Intrexx images
- Intrexx application packages (.zip files)

## Architecture Overview

The Kubernetes deployment consists of the following components:

1. **Intrexx Portal Pods**: Stateless application servers running the Intrexx portal
2. **PostgreSQL Database**: Persistent storage for Intrexx data
3. **Solr Search**: Search engine for Intrexx applications
4. **Zookeeper**: Coordination service for Solr
5. **Ingress Controller**: For load balancing and routing external traffic
6. **Application ConfigMaps/Secrets**: For storing application-specific configurations

## Platform Deployment

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

# Applications to be pre-installed
applications:
  - name: crm
    enabled: true
    version: "1.0.0"
    configMap: "crm-config"
  - name: workflow
    enabled: true
    version: "2.1.0"
    configMap: "workflow-config"
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

## Managing Individual Applications

### Deploying a New Application

1. Create an application package ConfigMap:

```bash
kubectl create configmap app-package --from-file=app.zip=/path/to/your/application.zip -n intrexx
```

2. Apply the application deployment:

```bash
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: deploy-app-job
  namespace: intrexx
spec:
  template:
    spec:
      containers:
      - name: deploy-app
        image: unitedplanet/intrexx:latest
        command: ["/bin/bash", "-c"]
        args:
        - |
          cd /opt/intrexx/bin
          ./ixdeployer.sh -a /tmp/app/app.zip -p portal
        volumeMounts:
        - name: app-package
          mountPath: /tmp/app
        - name: portal-data
          mountPath: /opt/intrexx/org
        - name: intrexx-cfg
          mountPath: /opt/intrexx/cfg
      restartPolicy: Never
      volumes:
      - name: app-package
        configMap:
          name: app-package
      - name: portal-data
        persistentVolumeClaim:
          claimName: intrexx-portal-portal-data
      - name: intrexx-cfg
        persistentVolumeClaim:
          claimName: intrexx-portal-cfg
  backoffLimit: 3
EOF
```

3. Monitor the deployment:

```bash
kubectl logs -f job/deploy-app-job -n intrexx
```

### Updating an Existing Application

1. Create a new ConfigMap with the updated application package:

```bash
kubectl create configmap app-update --from-file=app.zip=/path/to/your/updated-application.zip -n intrexx
```

2. Apply the update job:

```bash
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: update-app-job
  namespace: intrexx
spec:
  template:
    spec:
      containers:
      - name: update-app
        image: unitedplanet/intrexx:latest
        command: ["/bin/bash", "-c"]
        args:
        - |
          cd /opt/intrexx/bin
          ./ixdeployer.sh -u -a /tmp/app/app.zip -p portal
        volumeMounts:
        - name: app-package
          mountPath: /tmp/app
        - name: portal-data
          mountPath: /opt/intrexx/org
        - name: intrexx-cfg
          mountPath: /opt/intrexx/cfg
      restartPolicy: Never
      volumes:
      - name: app-package
        configMap:
          name: app-update
      - name: portal-data
        persistentVolumeClaim:
          claimName: intrexx-portal-portal-data
      - name: intrexx-cfg
        persistentVolumeClaim:
          claimName: intrexx-portal-cfg
  backoffLimit: 3
EOF
```

### Removing an Application

```bash
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: remove-app-job
  namespace: intrexx
spec:
  template:
    spec:
      containers:
      - name: remove-app
        image: unitedplanet/intrexx:latest
        command: ["/bin/bash", "-c"]
        args:
        - |
          cd /opt/intrexx/bin
          ./ixdeployer.sh -r -n APP_NAME -p portal
        volumeMounts:
        - name: portal-data
          mountPath: /opt/intrexx/org
        - name: intrexx-cfg
          mountPath: /opt/intrexx/cfg
      restartPolicy: Never
      volumes:
      - name: portal-data
        persistentVolumeClaim:
          claimName: intrexx-portal-portal-data
      - name: intrexx-cfg
        persistentVolumeClaim:
          claimName: intrexx-portal-cfg
  backoffLimit: 3
EOF
```

Replace `APP_NAME` with the name of the application you want to remove.

## Recreating the Intrexx Platform from Scratch

If you need to completely recreate your Intrexx platform:

1. Delete the existing deployment:

```bash
helm uninstall intrexx-portal -n intrexx
```

2. Optionally, delete persistent volumes if you want to start completely fresh:

```bash
kubectl delete pvc --all -n intrexx
```

3. Reinstall with a clean configuration:

```bash
helm install intrexx-portal intrexx-charts/intrexx-portal -f values.yaml -n intrexx
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
- Application packages and configurations

To create a backup of your applications:

```bash
kubectl exec -it $(kubectl get pods -l app.kubernetes.io/name=intrexx-portal -o jsonpath='{.items[0].metadata.name}' -n intrexx) -n intrexx -- bash -c "cd /opt/intrexx/bin && ./ixbackup.sh -d /tmp/backup -a"
kubectl cp intrexx/$(kubectl get pods -l app.kubernetes.io/name=intrexx-portal -o jsonpath='{.items[0].metadata.name}' -n intrexx):/tmp/backup ./intrexx-backup
```

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
4. **Application deployment failures**: Check application package format and compatibility

For more detailed troubleshooting, check the logs:

```bash
kubectl logs -n intrexx -l app.kubernetes.io/name=intrexx-portal
```

For application-specific issues:

```bash
kubectl exec -it $(kubectl get pods -l app.kubernetes.io/name=intrexx-portal -o jsonpath='{.items[0].metadata.name}' -n intrexx) -n intrexx -- bash -c "cat /opt/intrexx/log/portal_*.log | grep -i error"
```
