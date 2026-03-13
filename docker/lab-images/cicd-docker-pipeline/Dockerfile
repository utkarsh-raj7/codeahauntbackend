FROM docker:24-dind
RUN apk add --no-cache bash git nano curl
COPY init.sh /usr/local/bin/lab-init.sh
COPY app/ /home/labuser/app/
RUN chmod +x /usr/local/bin/lab-init.sh && mkdir -p /home/labuser
EXPOSE 7681
ENTRYPOINT ["sh","-c","dockerd &>/tmp/dockerd.log & sleep 3; ttyd -p 7681 -W bash -- -c 'bash /usr/local/bin/lab-init.sh; exec bash'"]
