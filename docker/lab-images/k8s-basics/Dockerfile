FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    curl \
    bash \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    curl -fsSL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install ttyd
RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.${ARCH} \
    && chmod +x ttyd.${ARCH} \
    && mv ttyd.${ARCH} /usr/local/bin/ttyd

# Create non-root user
RUN useradd -m -u 1000 labuser
USER 1000

EXPOSE 7681
ENTRYPOINT ["ttyd", "-p", "7681", "-W", "bash"]
