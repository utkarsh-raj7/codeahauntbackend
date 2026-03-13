FROM python:3.11-slim
RUN apt-get update && apt-get install -y bash nano curl \
    && pip install requests pyyaml \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.aarch64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY exercises/ /home/labuser/exercises/
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh && chown -R labuser:labuser /home/labuser
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
