FROM alpine

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV GOTTY_TAG_VER=v1.0.1

# Обновляем пакеты и ставим зависимости с кешем
RUN apk update && apk upgrade && \
    apk add --update-cache bash curl wget tar && \
    rm -rf /var/cache/apk/*

# Ставим gotty
RUN curl -sLk https://github.com/yudai/gotty/releases/download/${GOTTY_TAG_VER}/gotty_linux_amd64.tar.gz \
    | tar xz -C /usr/local/bin

# Ставим sshx
RUN wget -q https://sshx.io/get -O /tmp/get && \
    bash /tmp/get && \
    rm -f /tmp/get

# Копируем скрипты
COPY /openbox.sh /openbox.sh
COPY /run_gotty.sh /run_gotty.sh

RUN chmod +x /openbox.sh /run_gotty.sh

# Порты
EXPOSE 8080
EXPOSE 8000

# Запускаем оба процесса
CMD ["/bin/bash", "-c", "/run_gotty.sh & sshx"]
