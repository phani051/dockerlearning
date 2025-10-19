# Step 1: Build the React app
FROM node:18 AS build

WORKDIR /app

# Copy package.json and package-lock.json (if exists)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy all source files
COPY . .

# Fix OpenSSL issue
ENV NODE_OPTIONS=--openssl-legacy-provider
RUN npm run build

# Step 2: Serve using Nginx
FROM nginx:alpine

# Copy build output to Nginx html folder
COPY --from=build /app/build /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
