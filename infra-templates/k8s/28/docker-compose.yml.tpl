kubelet:
    labels:
        io.rancher.container.dns: "true"
        io.rancher.container.create_agent: "true"
        io.rancher.container.agent.role: environmentAdmin
        io.rancher.scheduler.global: "true"
        {{- if eq .Values.CONSTRAINT_TYPE "required" }}
        io.rancher.scheduler.affinity:host_label: compute=true
        {{- end }}
    command:
        - kubelet
        - --kubeconfig=/etc/kubernetes/ssl/kubeconfig
        - --api_servers=https://kubernetes.kubernetes.rancher.internal:6443
        - --allow-privileged=true
        - --register-node=true
        - --cloud-provider=${CLOUD_PROVIDER}
        - --healthz-bind-address=0.0.0.0
        - --cluster-dns=10.43.0.10
        - --cluster-domain=cluster.local
        - --network-plugin=cni
        - --cni-conf-dir=/etc/cni/managed.d
        {{- if and (ne .Values.REGISTRY "") (ne .Values.POD_INFRA_CONTAINER_IMAGE "") }}
        - --pod-infra-container-image=${REGISTRY}/${POD_INFRA_CONTAINER_IMAGE}
        {{- else if (ne .Values.POD_INFRA_CONTAINER_IMAGE "") }}
        - --pod-infra-container-image=${POD_INFRA_CONTAINER_IMAGE}
        {{- end }}
    image: joshwget/k8s
    volumes:
        - /run:/run
        - /var/run:/var/run
        - /sys:/sys:ro
        - /var/lib/docker:/var/lib/docker
        - /var/lib/kubelet:/var/lib/kubelet:shared
        - /var/log/containers:/var/log/containers
        - rancher-cni-driver:/etc/cni:ro
        - rancher-cni-driver:/opt/cni:ro
        - /dev:/host/dev
    net: host
    pid: host
    ipc: host
    privileged: true
    links:
        - kubernetes

{{- if eq .Values.CONSTRAINT_TYPE "required" }}
kubelet-unschedulable:
    labels:
        io.rancher.container.dns: "true"
        io.rancher.container.create_agent: "true"
        io.rancher.container.agent.role: environmentAdmin
        io.rancher.scheduler.global: "true"
        io.rancher.scheduler.affinity:host_label_ne: compute=true
    command:
        - kubelet
        - --kubeconfig=/etc/kubernetes/ssl/kubeconfig
        - --api_servers=https://kubernetes.kubernetes.rancher.internal:6443
        - --allow-privileged=true
        - --register-node=true
        - --cloud-provider=${CLOUD_PROVIDER}
        - --healthz-bind-address=0.0.0.0
        - --cluster-dns=10.43.0.10
        - --cluster-domain=cluster.local
        - --network-plugin=cni
        - --cni-conf-dir=/etc/cni/managed.d
        {{- if and (ne .Values.REGISTRY "") (ne .Values.POD_INFRA_CONTAINER_IMAGE "") }}
        - --pod-infra-container-image=${REGISTRY}/${POD_INFRA_CONTAINER_IMAGE}
        {{- else if (ne .Values.POD_INFRA_CONTAINER_IMAGE "") }}
        - --pod-infra-container-image=${POD_INFRA_CONTAINER_IMAGE}
        {{- end }}
        - --register-schedulable=false
    image: joshwget/k8s
    volumes:
        - /run:/run
        - /var/run:/var/run
        - /sys:/sys:ro
        - /var/lib/docker:/var/lib/docker
        - /var/lib/kubelet:/var/lib/kubelet:shared
        - /var/log/containers:/var/log/containers
        - rancher-cni-driver:/etc/cni:ro
        - rancher-cni-driver:/opt/cni:ro
        - /dev:/host/dev
    net: host
    pid: host
    ipc: host
    privileged: true
    links:
        - kubernetes
{{- end }}

proxy:
    labels:
        io.rancher.container.dns: "true"
        io.rancher.scheduler.global: "true"
        {{- if eq .Values.CONSTRAINT_TYPE "required" }}
        io.rancher.scheduler.affinity:host_label: compute=true
        {{- end }}
    command:
        - kube-proxy
        - --master=https://kubernetes.kubernetes.rancher.internal:6443
        - --v=2
        - --healthz-bind-address=0.0.0.0
    image: joshwget/k8s
    privileged: true
    net: host
    links:
        - kubernetes

etcd:
    image: rancher/etcd:v2.3.7-11
    labels:
        {{- if eq .Values.CONSTRAINT_TYPE "required" }}
        io.rancher.scheduler.affinity:host_label: etcd=true
        {{- end }}
        io.rancher.scheduler.affinity:container_label_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
        RANCHER_DEBUG: 'true'
        EMBEDDED_BACKUPS: '${EMBEDDED_BACKUPS}'
        BACKUP_PERIOD: '${BACKUP_PERIOD}'
        BACKUP_RETENTION: '${BACKUP_RETENTION}'
        ETCD_HEARTBEAT_INTERVAL: '${ETCD_HEARTBEAT_INTERVAL}'
        ETCD_ELECTION_TIMEOUT: '${ETCD_ELECTION_TIMEOUT}'
    volumes:
    - etcd:/pdata:z
    - /var/etcd/backups:/data-backup:z

kubernetes:
    labels:
        {{- if eq .Values.CONSTRAINT_TYPE "required" }}
        io.rancher.scheduler.affinity:host_label: orchestration=true
        {{- end }}
        io.rancher.container.create_agent: "true"
        io.rancher.container.agent.role: environmentAdmin
        io.rancher.sidekicks: kube-hostname-updater
    command:
        - kube-apiserver
        - --storage-backend=etcd2
        - --service-cluster-ip-range=10.43.0.0/16
        - --etcd-servers=http://etcd.kubernetes.rancher.internal:2379
        - --insecure-bind-address=0.0.0.0
        - --insecure-port=0
        - --cloud-provider=${CLOUD_PROVIDER}
        - --allow_privileged=true
        - --admission-control=NamespaceLifecycle,LimitRanger,SecurityContextDeny,ResourceQuota,ServiceAccount
        - --client-ca-file=/etc/kubernetes/ssl/ca.pem
        - --tls-cert-file=/etc/kubernetes/ssl/cert.pem
        - --tls-private-key-file=/etc/kubernetes/ssl/key.pem
        - --runtime-config=batch/v2alpha1
        - --authentication-token-webhook-config-file=/etc/kubernetes/authconfig
        - --runtime-config=authentication.k8s.io/v1beta1=true
        {{- if eq .Values.RBAC "true" }}
        - --authorization-mode=RBAC
        - --runtime-config=rbac.authorization.k8s.io/v1alpha1=true
        {{- end }}
    environment:
        KUBERNETES_URL: https://kubernetes.kubernetes.rancher.internal:6443
    image: joshwget/k8s
    links:
        - etcd
        - rancher-kubernetes-auth

kube-hostname-updater:
    net: container:kubernetes
    command:
        - etc-host-updater
    image: rancher/etc-host-updater:v0.0.2
    links:
        - kubernetes

kubectld:
    labels:
        {{- if eq .Values.CONSTRAINT_TYPE "required" }}
        io.rancher.scheduler.affinity:host_label: orchestration=true
        {{- end }}
        io.rancher.k8s.token: "true"
        io.rancher.k8s.kubectld: "true"
    command:
        - sleep
        - infinity
    image: joshwget/kubectld
    privileged: true

scheduler:
    command:
        - kube-scheduler
        - --master=https://kubernetes.kubernetes.rancher.internal:6443
        - --address=0.0.0.0
    image: joshwget/k8s
    {{- if eq .Values.CONSTRAINT_TYPE "required" }}
    labels:
        io.rancher.scheduler.affinity:host_label: orchestration=true
        {{- end }}
    links:
        - kubernetes

controller-manager:
    command:
        - kube-controller-manager
        - --master=https://kubernetes.kubernetes.rancher.internal:6443
        - --cloud-provider=${CLOUD_PROVIDER}
        - --address=0.0.0.0
        - --kubeconfig=/etc/kubernetes/ssl/kubeconfig
        - --root-ca-file=/etc/kubernetes/ssl/ca.pem
        - --service-account-private-key-file=/etc/kubernetes/ssl/key.pem
    image: joshwget/k8s
    labels:
        {{- if eq .Values.CONSTRAINT_TYPE "required" }}
        io.rancher.scheduler.affinity:host_label: orchestration=true
        {{- end }}
        io.rancher.container.create_agent: "true"
        io.rancher.container.agent.role: environmentAdmin
    links:
        - kubernetes

rancher-kubernetes-agent:
    labels:
        {{- if eq .Values.CONSTRAINT_TYPE "required" }}
        io.rancher.scheduler.affinity:host_label: orchestration=true
        {{- end }}
        io.rancher.container.create_agent: "true"
        io.rancher.container.agent.role: agent,environmentAdmin
        io.rancher.container.agent_service.labels_provider: "true"
    environment:
        KUBERNETES_URL: https://kubernetes.kubernetes.rancher.internal:6443
    image: rancher/kubernetes-agent:v0.6.1
    privileged: true
    volumes:
        - /var/run/docker.sock:/var/run/docker.sock
    links:
        - kubernetes

{{- if eq .Values.ENABLE_RANCHER_INGRESS_CONTROLLER "true" }}
rancher-ingress-controller:
    image: joshwget/lb-controller
    labels:
        {{- if eq .Values.CONSTRAINT_TYPE "required" }}
        io.rancher.scheduler.affinity:host_label: orchestration=true
        {{- end }}
        io.rancher.container.create_agent: "true"
        io.rancher.container.agent.role: environmentAdmin
    environment:
        KUBERNETES_URL: https://kubernetes.kubernetes.rancher.internal:6443
    command:
        - lb-controller
        - --controller=kubernetes
        - --provider=rancher
    links:
        - kubernetes
    health_check:
        request_line: GET /healthz HTTP/1.0
        port: 10241
        interval: 2000
        response_timeout: 2000
        unhealthy_threshold: 3
        healthy_threshold: 2
        initializing_timeout: 60000
        reinitializing_timeout: 60000
{{- end }}

rancher-kubernetes-auth:
    image: joshwget/kubernetes-auth
    labels:
        {{- if eq .Values.CONSTRAINT_TYPE "required" }}
        io.rancher.scheduler.affinity:host_label: orchestration=true
        {{- end }}
        io.rancher.container.create_agent: "true"
        io.rancher.container.agent.role: environmentAdmin

{{- if eq .Values.ENABLE_ADDONS "true" }}
addon-starter:
    image: joshwget/k8s
    labels:
        {{- if eq .Values.CONSTRAINT_TYPE "required" }}
        io.rancher.scheduler.affinity:host_label: orchestration=true
        {{- end }}
        io.rancher.container.create_agent: 'true'
        io.rancher.container.agent.role: environmentAdmin
    environment:
        KUBERNETES_URL: https://kubernetes.kubernetes.rancher.internal:6443
        REGISTRY: ${REGISTRY}
        INFLUXDB_HOST_PATH: ${INFLUXDB_HOST_PATH}
    command:
        - addons-update.sh
    links:
        - kubernetes
{{- end }}
