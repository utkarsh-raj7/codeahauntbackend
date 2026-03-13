FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl bash nano python3 \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/prometheus/prometheus/releases/download/v2.50.1/prometheus-2.50.1.linux-amd64.tar.gz \
    | tar xz -C /opt/ && ln -s /opt/prometheus-2.50.1.linux-amd64 /opt/prometheus
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.aarch64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY prometheus.yml /etc/prometheus/prometheus.yml
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681 9090
ENTRYPOINT ["ttyd","-p","7681","-W","bash","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
