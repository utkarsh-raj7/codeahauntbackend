FROM docker:24-dind
RUN apk add --no-cache bash curl nano python3
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.aarch64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd 2>/dev/null || \
    apk add --no-cache ttyd
COPY init.sh /usr/local/bin/lab-init.sh
COPY sample-app/ /home/labuser/sample-app/
RUN chmod +x /usr/local/bin/lab-init.sh
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","dockerd &>/tmp/dockerd.log & sleep 3; bash /usr/local/bin/lab-init.sh; exec bash"]
