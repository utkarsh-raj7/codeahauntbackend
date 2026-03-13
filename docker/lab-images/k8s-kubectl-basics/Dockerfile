FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl bash nano sudo \
    && rm -rf /var/lib/apt/lists/*
# kubectl
RUN curl -fsSL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl
# k3s for local cluster
RUN curl -fsSL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 || true
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser \
    && echo "labuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","sudo bash /usr/local/bin/lab-init.sh; exec bash"]
