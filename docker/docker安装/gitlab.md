# docker安装gitlab

gitlab.yml
```
version: '2'
services:
    gitlab:
      image: 'gitlab/gitlab-ce:11.9.9-ce.0'
      container_name: "gitlab"
      restart: unless-stopped
      privileged: true
      hostname: 'gitlab'
      environment:
        TZ: 'Asia/Shanghai'
        GITLAB_OMNIBUS_CONFIG: |
          external_url 'http://129.204.133.242'
          gitlab_rails['time_zone'] = 'Asia/Shanghai'
          gitlab_rails['smtp_enable'] = true
          gitlab_rails['smtp_address'] = "smtp.aliyun.com"
          gitlab_rails['smtp_port'] = 465
          gitlab_rails['smtp_user_name'] = "kimasd102419@aliyun.com"  #用自己的aliyun邮箱
          gitlab_rails['smtp_password'] = "axbc1kof"
          gitlab_rails['smtp_domain'] = "aliyun.com"
          gitlab_rails['smtp_authentication'] = "login"
          gitlab_rails['smtp_enable_starttls_auto'] = true
          gitlab_rails['smtp_tls'] = true
          gitlab_rails['gitlab_email_from'] = 'kimasd102419@aliyun.com'
          gitlab_rails['gitlab_shell_ssh_port'] = 22
      ports:
        - '80:80'
        - '443:443'
        - '22:22'
      volumes:
        - /opt/gitlab/config:/etc/gitlab
        - /opt/gitlab/data:/var/opt/gitlab
        - /opt/gitlab/logs:/var/log/gitlab
```
docker-compose -f gitlab.yml up -d