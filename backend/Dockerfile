FROM node:20-alpine

RUN apk add --no-cache openssl openssl-dev libc6-compat

WORKDIR /usr/src/app

COPY package*.json ./
# Cài đặt toàn bộ dependencies bao gồm cả prisma
RUN npm install

# Copy thư mục prisma chứa file schema.prisma vào trước
COPY prisma ./prisma/

# TẠO PRISMA CLIENT NGAY LÚC BUILD
RUN npx prisma generate

COPY . .

RUN npm run build

EXPOSE 3000

CMD ["npm", "run", "start:prod"]