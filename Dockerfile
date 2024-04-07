### STAGE 0: Build Client ###
FROM node:20-alpine AS build
WORKDIR /client
COPY /client /client
RUN npm ci && npm cache clean --force
RUN npm run generate

### STAGE 1: Build Server & Add Client ###
FROM sandreas/tone:v0.1.5 AS tone
FROM node:20-alpine

ENV NODE_ENV=production

COPY index.js package* /
COPY server server

RUN echo "**** Install Dependencies ****" && \
    apk update && \
    apk add --no-cache --update --upgrade \
        curl \
        g++ \
        ffmpeg \
        make \
        python3 \
        tini \
        tzdata && \
    echo "**** Install NPM Modules ****" && \
    npm ci --omit=dev && npm cache clean --force && \
    echo "**** Remove Build Dependencies ****" && \
    apk del make python3 g++

COPY --from=tone /usr/local/bin/tone /usr/local/bin/
COPY --from=build /client/dist /client/dist

EXPOSE 80

ENTRYPOINT ["tini", "--"]
CMD ["node", "index.js"]
