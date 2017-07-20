test-agent:
    labels:
        io.rancher.container.create_agent: "true"
        io.rancher.container.agent.role: agent,environmentAdmin
        io.rancher.container.agent_service.labels_provider: "true"
        io.rancher.k8s.agent: "true"
    environment:
        KUBERNETES_URL: https://kubernetes.kubernetes.rancher.internal:6443
    image: rancher/kubernetes-agent:v0.6.2
    privileged: true
    volumes:
        - /var/run/docker.sock:/var/run/docker.sock
    links:
        - kubernetes
    command:
        - sleep
        - 1000000
