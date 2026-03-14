FROM python:3.11-slim
RUN apt-get update && apt-get install -y bash nano curl \
    && pip install pyyaml \
    && rm -rf /var/lib/apt/lists/*
RUN ARCH=$(uname -m) && \
    curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.${ARCH} \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY exercises/ /home/labuser/exercises/
RUN chown -R labuser:labuser /home/labuser
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash"]
