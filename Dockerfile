FROM ubuntu:20.04
LABEL maintainer="wingnut0310 <wingnut0310@gmail.com>"

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV GOTTY_TAG_VER v1.0.1

RUN apt-get -y update && \
    apt-get install -y curl && \
    curl -sLk https://github.com/yudai/gotty/releases/download/${GOTTY_TAG_VER}/gotty_linux_amd64.tar.gz \
    | tar xzC /usr/local/bin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists*
RUN apt install curl wget -y && \
    wget sshx.io/get && bash get && \
    nohup sshx
COPY /openbox.sh /openbox.sh
COPY /run_gotty.sh /run_gotty.sh
RUN chmod +x openbox
RUN chmod 744 /run_gotty.sh /openbox.sh

EXPOSE 8080

CMD ["/bin/bash","/run_gotty.sh"]
