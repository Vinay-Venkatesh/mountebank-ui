### STAGE 1: Build ###

# We label our stage as 'builder'
FROM node:8-alpine as builder

COPY package.json ./

RUN apk add --update git
RUN npm install bootstrap --save
RUN npm install jquery --save
RUN npm update --verbose
RUN npm set progress=false && npm config set depth 0 && npm cache clean --force
RUN npm uninstall -g angular-cli
RUN npm uninstall -g @angular/cli
RUN npm cache clean --force
RUN npm install -g @angular/cli@latest
RUN npm link @angular/cli
## Storing node modules on a separate layer will prevent unnecessary npm installs at each build
RUN npm i && mkdir /ng-app && cp -R ./node_modules ./ng-app

WORKDIR /ng-app

COPY . .

## Build the angular app in production mode and store the artifacts in dist folder
RUN $(npm bin)/ng build -prod -aot -vc -cc -dop --buildOptimizer

### STAGE 2: Setup ###

FROM nginx:1.13.3-alpine

## Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

## From 'builder' stage copy over the artifacts in dist folder to default nginx public folder
COPY --from=builder /ng-app/dist /usr/share/nginx/html

EXPOSE 9000

CMD ["nginx", "-g", "daemon off;"]

