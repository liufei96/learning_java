Web 服务和应用是目前互联网技术领域的热门技术。本章将重点介绍如何使用 Docker 来运行常见的 Web 服务器（包括 Apache、Nginx、Tomcat 等），以及一些常用应用（包括 LAMP CI/CD) ，通过介绍具体的镜像构建方法与使用步骤展示容器的强大功能。 

本章会展示两种创建镜像的过程。其中一些操作比较简单的镜像使用 Dockerfile 来创建， 而像 Weblogic 这样复杂的应用，则使用 commit 方式来创建，读者可根据自己的需求进行 选择。

# 11.1 Apache

Apache 是一个高稳定性的、商业级别的开源 Web 服务器，是目前世界使用排名第一的 Web服务器软件。由于其良好的跨平台和安全性， Apache 被广泛应用在多种平台和操作系统上。 Apache 作为软件基金会支持的项目，其开发者社区完善而高效，自1995 年发布至今，一直以高标准进行维护与开发。 Apache 音译为阿帕奇，源 自美国西南部一个印第安人部落的名称（阿帕奇族）。

## 1. 使用DockerHub镜像

DockerHub 官方提供的 Apache 镜像，并不带 PHP 环境。如果需要 PHP 环境支持， 可以选择 PHP 镜像 (https://registry.hub.docker.com/_/php/ ），并请使用含－apache 标签的镜像， 如7.0.7-apache 。如果仅需要使用 Apache 运行静态 HTML 文件，则使用默认官方镜像即可。

编写 Dockerfile 文件，内容如下：

```dockerfile
FROM httpd:2.4
COPY ./public-html /usr/local/apache2/htdocs/
```

创建项目目录 public-html, 并在此目录下创建 index.html 文件。

```html
<!DOCTYPE html> 
<html> 
  <body> 
	<P>Hello, Docker!</p> 
   </body>
</html> 
```

构建自定义镜像：

```shell
[root@192 dokcer]# docker build -t apache2-image .
.....
Successfully built 3c8f287056b0
Successfully tagged apache2-image:latest
```

运行镜像

```shell
[root@192 dokcer]# docker run -it --name my-apache-app -p 80:80 -v "$PWD":/usr/local/apache2/htdocs/ httpd:2.4
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 172.17.0.2. Set the 'ServerName' directive globally to suppress this message
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 172.17.0.2. Set the 'ServerName' directive globally to suppress this message
[Tue Aug 30 13:40:00.548411 2022] [mpm_event:notice] [pid 1:tid 140250533023040] AH00489: Apache/2.4.52 (Unix) configured -- resuming normal operations
[Tue Aug 30 13:40:00.581340 2022] [core:notice] [pid 1:tid 140250533023040] AH00094: Command line: 'httpd -D FOREGROUND'
```

![image-20220830214139094](.\image\11-docker-apache.png)

## 2. 使用自定义镜像

首先，创建一个 apache_ubuntu 工作目录，在其中创建 Dockerfile 文件、 run.sh 文件和 sample 目录：

```shell
[root@192 dokcer]# mkdir apache_ubuntu && cd apache_ubuntu
[root@192 apache_ubuntu]# touch Dockerfile run.sh
[root@192 apache_ubuntu]# mkdir sample
```

下面是 Dockerfile 的内容和各个部分的说明：

```dockerfile
# 设置继承用户创建的sshd镜像
FROM sshd:dockerfile

# 创建者的基本信息
MAINTAINER docker_user (1583409404@qq.com@docker.com) 

# 设置环境变量，所有操作都是非交互式的
ENV DEBIAN_FRONTEND noninteractive

# 安装
RUN apt-get -yq install apache2 && \
	apt-get -y install tzdata && \
	rm -rf /var/lib/apt/lists/*
	
# 注意这里要更改系统的时区设置，因为在 Web 应用中经常会用到时区这个系统变量，默认 Ubun 的设置会让你的应用程序发生不可思议的效果
RUN echo "Asia/Shanghai" > /etc/timezone && \
	dpkg-reconfigure -f noninteractive tzdata

# 添加用户的脚本，井设置权限，这会覆盖之前放在这个位置的脚本
ADD run.sh /run.sh
RUN chmod 755 /*.sh

# 添加一个示例的 Web 站点，删掉默认安装在 apache 文件夹下面的文件，并将用户添加的示例用软链接链到/var/www/html 目录下面
RUN mkdir -p /var/lock/apache2 && && mkdir -p /var/run/apache2 && mkdir -p /app && rm -fr /var/www/html && ln -s /app /var/www/html
COPY sample/ /app

# 设置 apache 相关的一些变量，在容器启动的时候可以使用 -e 参数替代
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_SERVER_MIN admin@localhost
ENV APACHE_SERVERNAME localhost
ENV APACHE_SERVERALIAS docker.localhost
ENV APACHE_DOCUMENTROOT /var/www

EXPOSE 80 
WORKDIR /app 
CMD ["/run.sh"]
```

sample目录下创建一个index.html文件，内容如下：

```html
<!DOCTYPE html> 
<html> 
  <body> 
	<P>Hello, Docker!</p> 
   </body>
</html> 
```

run. sh 脚本内容也很简单，只是启动 apache 服务：

```shell
# !/bin/bash 
exec apache2 -D FOREGROUND
```

此时， apache_ubuntu 目录下面的文件结构为：

```shell
tree .
|-- Dockerfile
|-- run.sh
`-- sample
	`-- index.html

# 1个directory 3个file
```

下面，开始创建 apache:ubuntu 镜像。

使用 docker build 命令创建 apache:ubuntu 镜像，注意命令最后的"."

```shell
[root@192 apache_ubuntu]# docker build -t apache:ubuntu .
....
Successfully built 44c9fae4989e
Successfully tagged apache-ubuntu:latest
```

此时镜像已经创建成功了。用户可使用 docker images 指令查看本地新增的 apache: ubuntu 镜像：

```shell
[root@192 apache_ubuntu]# docker images
REPOSITORY                  TAG          IMAGE ID       CREATED              SIZE
apache-ubuntu               latest       44c9fae4989e   About a minute ago   276MB

```

接下来，使用 docker run 指令测试镜像。用户可以使用 -p 参数映射需要开放的端口 (22 和 80 端口）：

```shell
[root@192 apache_ubuntu]# docker run -d -P apache:ubuntu
[root@192 apache_ubuntu]# docker ps
CONTAINER ID   IMAGE           COMMAND     CREATED         STATUS         PORTS                                                                              NAMES
6ed2766e7dad   apache:ubuntu   "/run.sh"   6 seconds ago   Up 6 seconds   0.0.0.0:49164->22/tcp, :::49164->22/tcp, 0.0.0.0:49163->80/tcp, :::49163->80/tcp   silly_williams

```

测试

```shell
[root@192 apache_ubuntu]# curl 127.0.0.1:49163
<!DOCTYPE html>
<html>
  <body>
        <P>Hello, Docker!</p>
   </body>
</html>
```

也可以在其他设备上通过访问宿主主机 ip:49163 来访问 sample 站点。

下面，用户看看 Dockerfile 创建的镜像拥有继承的特性。不知道有没有细心的读者发现， apache 镜像的 Dockerfile 中只用 EXPOSE 定义了对外开放的 80 端口，而在 docker ps  -a 命令的返回中，却看到新启动的容器映射了 个端口： 22 和 80

但是实际上，当尝试使用 SSH 登录到容器时，会发现无法登录。这是因为在 run.sh 脚本中并未启动 SSH 服务。这说明在使用 Dockerfile 创建镜像时，会继承父镜像的开放端 口，但却不会继承启动命令。因此，需要在 run.sh 脚本中添加启动 sshd 的服务的命令：

```shell
[root@192 apache_ubuntu]# cat run.sh
#!/bin/bash
/usr/sbin/sshd &
exec apache2 -D FOREGROUND
```

再次创建镜像：

```shell
[root@192 apache_ubuntu]# docker build -t apache:ubuntu .
...
Successfully built 173e8036071e
Successfully tagged apache:ubuntu
```

这次创建的镜像，将默认会同时启动 SSH Apache 服务。

下面，用户看看如何映射本地目录。用户可以通过映射本地目录的方式，来指定容器内 Apache 服务响应的内容，例如映射本地主机上当前目录下的 www 目录到容器内的 /var/www 目录：

```shell
[root@192 apache_ubuntu]# docker run -i -d -p 80:80 -p 103:22 -e APACHE_SERVERNAME=test -v $(pwd)/www:/app:ro apache:ubuntu

```

在当前目录内创建 www 目录，并放上自定义的页面 index.html, 内容为：

```html
<!DOCTYPE HTML PUBLIC 11-//IETF//DTD HTML 2.0//EN"> 
<html>
<head> 
<title>Hi Docker</title>
</head><body> 
<hl>Hi Docker</hl> 
<p>This is the firs day I meet the new world.</p> 
<P>How are you?</p> 
<hr> 
<address>Apache/2.4.7 (Ubuntu) Server 127.0.0.1 Port 80</address> 
</body>
</html>
```

测试验证

```shell
[root@192 apache_ubuntu]# curl 127.0.0.1

<!DOCTYPE HTML PUBLIC 11-//IETF//DTD HTML 2.0//EN">
<html>
<head>
<title>Hi Docker</title>
</head><body>
<hl>Hi Docker</hl>
<p>This is the firs day I meet the new world.</p>
<P>How are you?</p>
<hr>
<address>Apache/2.4.7 (Ubuntu) Server 127.0.0.1 Port 80</address>
</body>
</html>
[root@192 apache_ubuntu]# ssh 192.168.245.129 -p 103
The authenticity of host '[192.168.245.129]:103 ([192.168.245.129]:103)' can't be established.
ECDSA key fingerprint is SHA256:j33O75x+cRlD5EPJA5a1GCCndBGjjn5DKAjtqxn4aMA.
ECDSA key fingerprint is MD5:62:bc:85:1b:a4:99:b6:32:8c:50:41:8e:24:65:d7:36.
Are you sure you want to continue connecting (yes/no)? yes
...

root@806bffa1be85:~# ls -l  /app
total 4
-rw-r--r--. 1 root root 294 Aug 30 15:21 index.html
```

# 11.2 Nginx

Nginx （发音为 “engine-x”) 是一款功能强大的开源 反向代理服务器，支持 HTTP、HTTPS、SMTP、POP3、IMAP 等协议。它也可以作为负载均衡器、 HTTP 缓存或 Web 服务器。 Nginx 一开始就专注于高并发和高性能的应用场景。它使用类 BSD 开源协议，支持 Linux、BSD、Mac、Solaris、AIX 等类 Unix 系统，同时也有 Windows 上的移植版本。

Nginx 特性如下：

- **热部署**：采用 master 管理进程与 worker 工作进程的分离设计，支持热部署。在不间 断服务的前提下，可以直接升级版本。也可以在不停止服务的情况下修改配置文件， 更换日志文件等。
- **高并发连接**： Nginx 可以轻松支持超过 100K 的并发，理论上支持的并发连接上限取决于机器内存。
- **低内存消耗**：在一般的情况下， 10K 个非活跃的 HTTP Keep -Alive连接在 Nginx 中仅 消耗 2.5MB 的内存，这也是 Nginx 支持高并发连接的基础。
- **响应快**：在正常的情况下，单次请求会得到更快的响应。在高峰期， Nginx 可以比其 他的 Web 服务器更快地响应请求。
- **高可靠性**： Nginx 是一个高可靠性的 Web 服务器，这也是用户为什么选择 Nginx 基本条件，现在很多的网站都在使用 Nginx, 足以说明 Nginx 的可靠性。高可靠性来自其核心框架代码的优秀设计和实现。

本节将首先介绍 Nginx 官方发行版本的镜像生成，然后介绍第三方发行版 Tengine 镜像的生成。

## 1. 使用 DockerHub 镜像

可以使用 docker run 指令直接运行官方 Nginx 镜像：

```shell
[root@192 ~]# docker run -d -p 80:80 --name webserver nginx
...
c7685222532ca2184c24127cc7d880a6f6ab6376b9fa46976dc2cb5b7f4c4852
```

然后使用 docker ps 指令查看当前运行的容器：

```shell
[root@192 ~]# docker ps
CONTAINER ID   IMAGE     COMMAND                  CREATED          STATUS          PORTS                               NAMES
c7685222532c   nginx     "/docker-entrypoint.…"   27 seconds ago   Up 24 seconds   0.0.0.0:80->80/tcp, :::80->80/tcp   webserver
```

目前 Nginx 容器已经在 0. 0. 0. 0: 80 启萌映射了 80 端口，此时可以打开刻览器访间此地址，就可以看到 Nginx 输出的页面：

![image-20220831223935798](.\image\11-docker-nginx-01.png)

1.9版本后的镜像支持 debug 模式，镜像包含 nginx debug, 可以支持更丰富的 log 信息：

```shell
docker run --name my-nginx -v /host/path/nginx.conf:/etc/nginx/nginx.conf:ro -d nginx nginx-debug -g 'daemon off;'
```

## 2. 自定义web页面

首先，新建 index.html 文件，内容如下：

```html
<html>
<title> text </title>
<body> 
    <div> 
        hello world 
    </div> 
</body> 
</html> 
```

然后使用 docker [container] run 指令运行，并将 index.html 文件挂载至容器 中，即可看到显示自定义的页面。

```shell
[root@192 ~]# [root@192 nginx]# docker run --name nginx-container -p 80:80 -v $(pwd)/index.html:/usr/share/nginx/html/index.html:ro -d nginx
```

另外，也可以使用 Dockerfile 来构建新镜像。 Dockerfile 内容如下：

```dockerfile
FROM nginx
COPY ./index.html /usr/share/nginx/html/
```

构建my-nginx

```shell
[root@192 nginx]# docker build -t my-nginx .
Sending build context to Docker daemon  3.072kB
...
Successfully built 94868f6da27d
Successfully tagged my-nginx:latest
```

运行

```shell
[root@192 nginx]# docker run -itd --name nginx-container-2 -p 80:80 my-nginx
```

(1) 使用自定义的dockerfile

```dockerfile
FROM sshd:dockerfile
# 下面是一些创建者的基本信息
MAINTAINER docker_user(1583409404@qq.com)
# 安装 nginx, 设置 nginx 以非 daemon 方式启动。
RUN apt-get install -y nginx && \
	apt-get -y install tzdata && \
	rm -rf /var/lib/apt/lists/* && \
	echo "\ndaemon off;" >> /etc/nginx/nginx.conf && \
	chown -R www-data:www-data /var/lib/nginx
	
# 注意这里要更改系统的时区设置，因为在 Web 应用中经常会用到时区这个系统变量，默认 Ubun 的设置会让你的应用程序发生不可思议的效果
RUN echo "Asia/Shanghai" > /etc/timezone && \
	dpkg-reconfigure -f noninteractive tzdata
	
# 添加用户的脚本，并设置权限，这会覆盖之前放在这个位置的脚本
ADD run.sh /run.sh
RUN chmod 755 /*.sh

# 定义可以被挂载的目录，分别是虚拟主机的挂载目录、证书目录、配置目录、和日志目录
VOLUME  ["/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx"]

# 定义工作目录
WORKDIR /etc/nginx

# 定义输出命令
CMD ["/run.sh"]

# 定义输出端口
EXPOSE 80
EXPOSE 443
```

(2) 查看run.sh 脚本文件内容

```shell
#!/bin/bash 
/usr/sbin/sshd & 
/usr/sbin/nginx 
```

(3) 创建镜像

```shell
[root@192 nginx]# docker build -t nginx:stable .
...
Successfully built 122fba6facd5
Successfully tagged nginx:stable
```

(4) 测试

启动容器，查看内部的 80 端口被映射到本地的 49154 端口：

```shell

[root@192 nginx]# docker run -d -P nginx:stable
6babffdfa8d982d3477fa9f8c5b0bc188665b9fbd13602f6fc5a7860c18272d7
[root@192 nginx]# docker ps
CONTAINER ID   IMAGE          COMMAND     CREATED         STATUS         PORTS                                                                                                                         NAMES
6babffdfa8d9   nginx:stable   "/run.sh"   3 seconds ago   Up 2 seconds   0.0.0.0:49155->22/tcp, :::49155->22/tcp, 0.0.0.0:49154->80/tcp, :::49154->80/tcp, 0.0.0.0:49153->443/tcp, :::49153->443/tcp   unruffled_lehmann
```

```shell
[root@192 nginx]# curl 127.0.0.1:49154   # 将看到nginx的index.html页面内容

```

## 3. 参数优化

为了能充分发挥 Nginx 的性能，用户可对系统内核参数做一些洞整。下面是一份常见的适合运行 Nginx 服务器的内核优化参数：

```shell
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 30
net.ipv4.ip_local_port_range = 1024 65000
```

## 4. 相关资源

Nginx 的相关资源如下：

-  Nginx 官网： https://www.nginx.com
- Nginx 官方仓库： https://github.com/nginx/nginx
- Nginx 官方镜像： https://hub.docker.com/_/nginx/
- Nginx 官方镜像仓库： https://github.com/nginxinc/docker-nginx
