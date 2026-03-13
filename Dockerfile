FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# Let the compose file override the command for dev watch mode
CMD ["npm", "run", "dev"]
