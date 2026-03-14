FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl \
    bash openssh-client openssh-server sudo nano \
    && rm -rf /var/lib/apt/lists/*
RUN ARCH=$(uname -m) && \
    curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.${ARCH} \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser \
    && echo "labuser:labpass" | chpasswd
RUN mkdir /var/run/sshd
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","-c","/usr/sbin/sshd; su - labuser -c 'bash /usr/local/bin/lab-init.sh; exec bash'"]
