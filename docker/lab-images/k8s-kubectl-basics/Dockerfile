FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl bash nano sudo \
    && rm -rf /var/lib/apt/lists/*
# kubectl — ARM64
RUN curl -fsSL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl" \
    -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl
# ttyd
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.aarch64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser \
    && echo "labuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
