FROM docker:24-dind
RUN apk add --no-cache bash curl nano
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
EXPOSE 7681
ENTRYPOINT ["sh","-c","dockerd &>/tmp/dockerd.log & sleep 3; ttyd -p 7681 -W bash -- -c 'bash /usr/local/bin/lab-init.sh; exec bash'"]
