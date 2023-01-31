# Builder
FROM node:16-alpine as build

WORKDIR /usr/app

COPY package-lock.json package.json ./
RUN npm ci

COPY . /usr/app

ARG REACT_APP_DISCORD_OAUTH
ARG REACT_APP_DISCORD_INVITE
ARG REACT_APP_SSH_SERVER
ARG REACT_APP_SSH_PORT
ENV REACT_APP_DISCORD_OAUTH $REACT_APP_DISCORD_OAUTH
ENV REACT_APP_SSH_SERVER $REACT_APP_SSH_SERVER
ENV REACT_APP_SSH_PORT $REACT_APP_SSH_PORT
ENV REACT_APP_DISCORD_INVITE $REACT_APP_DISCORD_INVITE
RUN npm run build

# Runner
FROM nginx:alpine

EXPOSE 80
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /usr/app/build /usr/share/nginx/html

RUN chown -R nginx:nginx /usr/share/nginx/html

ENTRYPOINT ["nginx", "-g", "daemon off;"]
