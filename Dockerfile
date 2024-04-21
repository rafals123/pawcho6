#Etap 1 budowy obrazu
#Użycie bazowego obrazu metodą od podstaw - from scratch
FROM scratch AS builder 
#Definicja zmiennej
ARG VERSION
#Użycie obrazu bazowego z minimalną zawartością systemu Linux Alpine
ADD alpine-minirootfs-3.19.1-x86_64.tar /
#Określenie katalogu roboczego, w którym będzie tworzona aplikacja app.js
WORKDIR /usr/app
#Skopiowanie plików z lokalnego systemu plików do środowiska kontenera 
COPY ./package.json ./
COPY ./app.js ./
#Aktualizacja pakietów APK, instalacja node.js i narzędzia npm oraz czyszczenie pamięci podręcznej cache
RUN apk update && apk add nodejs npm && rm -rf /var/cache/apk/*
#uruchomienie instalacji zależności zdefiniowanych w pliku package.json
RUN npm install
#Informacja o porcie, na którym kontener będzie nasłuchiwał
EXPOSE 3000
#Etap 2 budowy obrazu 
#Użycie obrazu Alpine z Nginx
FROM nginx:alpine
#Przechwycenie zmiennej środowiskowej zdefiniowanej w etapie 1 budowy obrazu
ARG VERSION
ENV APP_VERSION=${VERSION:-v1}
#Określenie katalogu roboczego
WORKDIR /usr/share/nginx/html
#Skopiowanie plików z poprzedniego etapu budowy obrazu do obecnego
COPY --from=builder /usr/app /usr/share/nginx/html
#Skopiowanie pliku default.conf (pliku konfiguracyjnego dla serwera Nginx) z lokalnego systemu plików do kontenera
COPY ./default.conf /etc/nginx/conf.d
#Aktualizacja pakietów APK, instalacja node.js oraz czyszczenie pamięci podręcznej cache
RUN apk update && apk add nodejs && rm -rf /var/cache/apk/*
#Informacja o porcie, na którym kontener będzie nasłuchiwał
EXPOSE 80
#Użycie komendy HEALTHCHECK umożliwiającej sprawdzenie poprawności działania kontenera
HEALTHCHECK --interval=10s --timeout=1s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:80 || exit 1
#Uruchomienie serwera Nginx oraz aplikacji app.js
CMD nginx -g "daemon off;" & node app.js  