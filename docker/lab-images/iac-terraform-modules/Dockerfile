FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl unzip nano bash \
    && curl -fsSL https://releases.hashicorp.com/terraform/1.7.4/terraform_1.7.4_linux_amd64.zip -o tf.zip \
    && unzip tf.zip -d /usr/local/bin/ && rm tf.zip && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY exercises/ /home/labuser/exercises/
RUN chown -R labuser:labuser /home/labuser
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash"]
