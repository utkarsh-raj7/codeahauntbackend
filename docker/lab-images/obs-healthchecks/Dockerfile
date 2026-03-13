FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y bash curl python3 nano \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY init.sh /usr/local/bin/lab-init.sh
COPY app.py /home/labuser/app.py
RUN chmod +x /usr/local/bin/lab-init.sh && chown labuser:labuser /home/labuser/app.py
USER labuser
WORKDIR /home/labuser
EXPOSE 7681 8080
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
