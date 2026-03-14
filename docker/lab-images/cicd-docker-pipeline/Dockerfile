FROM docker:24-dind
RUN apk add --no-cache bash git nano curl \
    && ARCH=$(uname -m) && curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.${ARCH} \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
COPY init.sh /usr/local/bin/lab-init.sh
COPY app/ /home/labuser/app/
RUN chmod +x /usr/local/bin/lab-init.sh && mkdir -p /home/labuser
EXPOSE 7681
ENTRYPOINT ["sh","-c","dockerd &>/tmp/dockerd.log & sleep 3; ttyd -p 7681 -W bash -- -c 'bash /usr/local/bin/lab-init.sh; exec bash'"]
