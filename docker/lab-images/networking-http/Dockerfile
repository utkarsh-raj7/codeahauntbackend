FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    bash curl wget jq python3 python3-pip \
    && pip3 install httpie requests \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
