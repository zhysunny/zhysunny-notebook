# docker安装redis

redis.yml
```
version: '3'
services:
  redis:  
    hostname: redis
    image: redis:5.0.4
    container_name: redis
    restart: unless-stopped
    command: redis-server /etc/redis.conf # 启动redis命令
    environment:
      - TZ=Asia/Shanghai
    volumes:
      - /etc/localtime:/etc/localtime:ro # 设置容器时区与宿主机保持一致
      - /opt/redis/data:/data
      - /opt/redis/conf:/etc/redis.conf
    ports:
        - "6379:6379"
```
docker-compose -f redis.yml up -d