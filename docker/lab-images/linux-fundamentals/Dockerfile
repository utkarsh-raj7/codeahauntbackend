FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    curl \
    bash \
    wget \
    vim \
    nano \
    tree \
    less \
    man-db \
    && rm -rf /var/lib/apt/lists/*

# Install ttyd
RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.aarch64 \
    && chmod +x ttyd.aarch64 \
    && mv ttyd.aarch64 /usr/local/bin/ttyd

# Create non-root user
RUN useradd -m -u 1000 labuser
USER 1000

EXPOSE 7681
ENTRYPOINT ["ttyd", "-p", "7681", "-W", "bash"]
