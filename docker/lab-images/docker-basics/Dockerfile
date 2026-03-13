FROM docker:24-dind
RUN apk add --no-cache bash curl nano ttyd
RUN adduser -D -u 1000 -s /bin/bash labuser \
    && addgroup labuser docker
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
EXPOSE 7681 2375
ENTRYPOINT ["ttyd","-p","7681","-W","sh","--","-c","dockerd &>/tmp/dockerd.log & sleep 3; bash /usr/local/bin/lab-init.sh; exec bash"]
