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

# 11.3 Tomcat

Tomcat 是由 Apache 软件基金会下属的 Jakarta 项目开发的一个 Servlet 容器，按照 Sun Microsystems 提供的技术规范，实现了对 Servlet、JavaServer Page (JSP) 的支持。同时，它提供了作为 Web 服务器的一些特有功能，如 Tomcat 管理和控制平台、安全歧管理和 Tomcat 阀等。由千 Tomcat 本身也内含 了一个 HTTP 服务器，也可以当作单独的 Web 服务器来使用。

下面将以 sun_jdk 1.8 tomcat 8.0 ubuntu 18.04 环境为例介绍如何定制 Tomcat 镜像。

## 1. 准备工作

创建 tomcat_8.0_jdk1.8 文件夹，从 www.oracle.com 网站上下载 sun_jdk 1. 8  压缩包，并解压。

创建 Dockerfile 和 run. sh 文件：

```shell
[root@192 dokcer]# mkdir tomcat8.0_jdk1.8
[root@192 dokcer]# cd tomcat8.0_jdk1.8/
[root@192 tomcat8.0_jdk1.8]# touch Dockerfile run.sh
```

解压后，tomcat_8.0_jdk1.8 目录下的文件结构如下

```shell
[root@192 tomcat8.0_jdk1.8]# ll
总用量 0
drwxr-xr-x. 9 root root 220 9月   1 22:32 apache-tomcat-8.5.82
-rw-r--r--. 1 root root   0 9月   1 22:29 Dockerfile
drwxr-xr-x. 8   10  143 255 7月  22 2017 jdk1.8.0_144
-rw-r--r--. 1 root root   0 9月   1 22:29 run.sh
```

## 2. Dockerfile 文件和其他脚本文件

Dockerfile 文件内容如下：

```shell
FROM sshd:dockerfile

# 下面是一些创建者的基本信息
MAINTAINER docker_user(1583409404@qq.com)

# 设置环境变量，所有操作都是非交互式的
ENV DEBIAN_FRONTEND noninteractive

# 安装跟 tomcat 用户认证相关的软件
RUN apt-get -y install tzdata && \
	apt-get install -yq --no-install-recommends wget pwgen ca-certificates && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*
	
# 注意这里要更改系统的时区设置，因为在 Web 应用中经常会用到时区这个系统变量，默认 Ubun 的设置会让你的应用程序发生不可思议的效果
RUN echo "Asia/Shanghai" > /etc/timezone && \
	dpkg-reconfigure -f noninteractive tzdata
	
# 设置环境变量
ENV CATALINA_HOME /tomcat
ENV JAVA_HOME /jdk1.8.0_144

# 复制tomcat和jdk到镜像中
COPY apache-tomcat-8.5.82 /tomcat
COPY jdk1.8.0_144 /jdk1.8.0_144
COPY manager.xml ${CATALINA_HOME}/conf/Catalina/localhost/

ADD create_tomcat_admin_user.sh /create_tomcat_admin_user.sh
ADD run.sh /run.sh
RUN chmod +x /*.sh
RUN chmod +x /tomcat/bin/*.sh

EXPOSE 8080
CMD ["/run.sh"]
```

创建tomcat 用户和密码脚本文件 create_tomcat＿admin_user.sh 文件，内容为：

```shell
#!/bin/bash 
if [ -f /.tomcat_admin_created ]; then
	echo "Tomcat 'admin' user already created"
	exit 0
fi
#generate password 
PASS=${TOMCAT_PASS:-$(pwgen -s 12 1)} 
word=$([ ${TOMCAT_PASS} ] && echo "preset" || echo "random") 

echo "=> Creating and admin user with a ${_word} password in Tomcat"
sed -i -r 's/<\/tomcat-users>//' ${CATALINA_HOME}/conf/tomcat-users.xml 
echo '<role rolename="manager-gui"/>' >> ${CATALINA_HOME}/conf/tomcat-users.xml 
echo '<role rolename="manager-script"/>' >> ${CATALINA_HOME}/conf/tomcat-users.xml 
echo '<role rolename="manager-jmx"/>' >> ${CATALINA_HOME}/conf/tomcat-users.xml 
echo '<role rolename="admin-gui"/>' >> ${CATALINA_HOME}/conf/tomcat-users.xml 
echo '<role rolename="admin-script"/>' >> ${CATALINA_HOME}/conf/tomcat-users.xml 
echo "<user username=\"admin\" password=\"${PASS}\" roles=\"manager-gui,manager-script， manager-jmx,admin-gui,admin-script\"/>" >> ${CATALINA_HOME}/conf/tomcat-users.xml 
echo '</tomcat-users>' >> ${CATALINA_HOME}/conf/tomcat-users.xml 
echo "=> Done!" 
touch /.tomcat_admin_created
echo "========================================================================"
echo "You can now configure this Tomcat server using:" 
echo ""
echo " admin:${PASS}" 
echo ""
echo "========================================================================"
```

创建manager.xml （主要是为了登录）

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Context privileged="true" antiResourceLocking="false"
         docBase="${catalina.home}/webapps/manager">
    <Valve className="org.apache.catalina.valves.RemoteAddrValve" allow="^.*$" />
</Context>
```

编写 run. sh 脚本文件，内容为：

```shell
#!/bin/bash
if [ ! -f /.tomcat＿admin_created ]; then 
	/create_tomcat_admin_user.sh 
fi 
/usr/sbin/sshd -D & 
exec ${CATALINA_HOME}/bin/catalina.sh run
```

## 3. 创建和测试镜像

通过下面的命令创建镜像tomcat8.0:jdk1.8

```shell
[root@192 tomcat8.0_jdk1.8]# docker build -t tomcat8.0:jdk1.8 .
...
Successfully built f6124b204f93
Successfully tagged tomcat8.0:jdk1.8
```

启动一个 tomcat 容器进行测试：

```shell
[root@192 tomcat8.0_jdk1.8]# docker run -d -P tomcat8.0:jdk1.8


[root@192 tomcat8.0_jdk1.8]# docker ps
CONTAINER ID   IMAGE              COMMAND     CREATED         STATUS         PORTS                                                                                  NAMES
5ff16426e4a3   tomcat8.0:jdk1.8   "/run.sh"   7 seconds ago   Up 6 seconds   0.0.0.0:49174->22/tcp, :::49174->22/tcp, 0.0.0.0:49173->8080/tcp, :::49173->8080/tcp   gallant_jemison
```

![image-20220901231705823](.\image\11-docker-tomcat.png)

从docker logs 可以得到密码

```shell
root@192 tomcat8.0_jdk1.8]# docker logs 5ff16426e4a3
=> Creating and admin user with a  password in Tomcat
=> Done!
========================================================================
You can now configure this Tomcat server using:

 admin:0lOrfTbkNJHB
...
```

点击页面的 Manager App，输入用户名和密码，登录之后，进入如下页面。

![image-20220902004806844](.\image\11-docker-tomcat-manager.png)



注意：在实际环境中，可以通过使用 -v 参数来挂载 Tomcat 的日志文件、程序所在目录、 以及与 Tomcat 相关的配置。

## 4. 相关资源

Tomcat 的相关资源如下：

- Tomcat 官网： http://tomcat.apache.org/
- Tomcat 官方仓库： https://github.com/apache/tomcat 
- Tomcat 官方镜像： https://huh.docker.com/_/tomcat/ 
- Tomcat 官方镜像仓库： https://github.com/docker-library/tomcat

# 11.5 LAMP 

LAMP (Linux-Apache-MySQL-PHP) 是目前流行的 Web 工具栈， 其中包括： Linux 操作系统， Apache 网络服务器， MySQL 数据库， Perl、PHP 或者 Python ．编程语言。其组成工具均是成熟的开源软件， LR 被大最网站所采用。和 Java/J2EE 架构相比， LAMP 具有 Web 资源丰富、轻量、快速开发等特点；和微软的 .NET 架构相比， LAMP 更具有通用、跨平台、高性能、 低价格的优势。因此 LAMP 技术栈得到了广泛的应用。

> 现在也有人用 Nginx 替换 Apache, 称为 LNMP 或 LEMP, 是十分类似的技术栈，并不影响整个技术框架的选型原则。

## 1. 使用官方镜像

用户可以使用自定义 Dockerfile 或者 Compose 方式运行 LAMP, 同时社区也提供了十分 成熟的 linode/lamp 和 tutum/lamp 镜像。

### (1) 使用 linode/lamp 镜像

首先，执行docker [container] run指令，直接运行镜像，并进入容器内部bash shell：

```shell
[root@192 ~]# docker run p- 80:80 -t -i linode/lamp /bin/bash
root@a449f11266a6:/#
```

在容器内部 shell 启动 Apache 以及 MySQL 服务：

```shell
root@a449f11266a6:/# service apache2 start
 * Starting web server apache2                                                                                                                                                       *
root@a449f11266a6:/# service mysql start
 * Starting MySQL database server mysqld                                                                                                                                             [ OK ]
 * Checking for tables which need an upgrade, are corrupt or were
not closed cleanly.
```

此时镜像中 Apache、MySQL 服务已经启动，可使用 docker ps 指令查看运行中的容器：

```shell
[root@192 ~]# docker ps
CONTAINER ID   IMAGE         COMMAND       CREATED         STATUS         PORTS                               NAMES
a449f11266a6   linode/lamp   "/bin/bash"   6 minutes ago   Up 6 minutes   0.0.0.0:80->80/tcp, :::80->80/tcp   heuristic_dijkstra
```

![image-20220903111308964](.\image\11-docker-lamp.png)

### (2) 使用 tutum/lamp 镜像

首先，执行 docker [container] run 指令，直接运行镜像：

```shell
[root@192 ~]# docker ps
CONTAINER ID   IMAGE        COMMAND     CREATED          STATUS         PORTS                                                                          NAMES
76fb089dbf37   tutum/lamp   "/run.sh"   10 seconds ago   Up 6 seconds   0.0.0.0:80->80/tcp, :::80->80/tcp, 0.0.0.0:3306->3306/tcp, :::3306->3306/tcp   zen_turing
```

![image-20220903111806530](.\image\11-docker-tutum.png)







### (3) 部署自定义PHP应用

默认的容器启动了一个 helloword 应用。读者可以基于此镜像，编辑 Dockerfile 来创建 自定义 LAMP 应用镜像。

在宿主主机上创建新的工作目录 lamp:

```shell
[root@192 ~]# cd dokcer/
[root@192 dokcer]# mkdir lamp
[root@192 dokcer]# cd lamp/
[root@192 lamp]# touch DOckerfile
```

在php 目录下里面创建 Dockerfile 文件，内容为：

```dockerfile
FROM tutum/lamp:latest
RUN rm -fr /app && git clone https//github.com/username/customapp.git /app
# 这里替换 https://github.com/username/customapp.git 地址为你自己的项目地址
EXPOSE 80 3306
CMD ["/run.sh"]
```

创建镜像，命名为 my-lamp-app：

```shell
$ docker build -t my-lamp-app . 
```

利用新创建镜像启动容器，注意启动时候指定 -d 参数，让容器后台运行：

```shell
$ docker run -d -p 8080:80 -p 3306:3306 my-lamp-app
```

在本地主机上使用 curl 命令测试应用程序是不是已经正常响应：

```shell
$ curl http://127.0.0.1:8080/
```

## 2. 相关资源

LAMP 的想更换资源如下：

- tutum LAMP 镜像：https://hub.docker.com/r/tutum/lamp/ 
- linode LAMP 镜像：https://hub.docker.com/r/linode/lamp/ 

# 11.6 持续开发与管理

信息行业日新月异，如何响应不断变化的需求，快速适应和保证软件的质量？持续集成 (Continuous Integration, CI) 正是针对解决这类问题的一种开发实践，它倡导开发团队定期进行 集成验证。集成通过自动化的构建来完成，包括自动编译、发布和测试，从而尽快地发现错误。

持续集成的特点包括：

- 鼓励自动化的周期性的过程，从检出代码、编译构建、运行测试、结果记录、测试统计等都是自动完成的，减少人工干预；
- 需要有持续集成系统的支持，包括代码托管机制支持，以及集成服务器等。

持续交付 (Continuous Delivery, CD) 则是经典的敏捷软件开发方法的自然延伸，它强调产品在修改后到部署上线的流程要敏捷化、自动化。甚至一些较小的改变也要尽早地部署上线，这与传统软件在较大版本更新后才上线的思路不同。

## 1. Jenkins 及官方镜像

Jenkins 是一个得到广泛应用的持续集成和持续交付的工具。作为 开源软件项目，它旨在提供一个开放易用的持续集成平台。 Jenkins 能实时监控集成中存在的错误，提供详细的日志文件和提醒功能，并用图表的形式形象地展示 项目构建的趋势和稳定性。 Jenkins 特点包括安装配置简单、支持详细的测试报表、分布式构建等。

Jenkis 自2.0 版本推出了 "Pipeline as Code" ，帮助 Jenkins 实现对 CI 和 CD 更好的支持。 通过 Pipeline, 将原本独立运行的多个任务连接起来，可以实现十分复杂的发布流程，如 11-9 所示。

![查看源图像](.\image\11-docker-jenkins.png)

Jenkins 官方在 DockerHub 上提供了全功能的基于官方发布版的 Docker 镜像。可以方便 地使用 docker [container] run 指令一键部署 Jenkins 服务：

```shell
[root@192 jenkins]# docker run -p 8080:8080 -p 50000:50000 jenkins/jenkins
...

Jenkins initial setup is required. An admin user has been created and a password generated.
Please use the following password to proceed to installation:

dce074ed4e11410bb448af81523d37ac

This may also be found at: /var/jenkins_home/secrets/initialAdminPassword
....

```

使用上面的密码进行登录：dce074ed4e11410bb448af81523d37ac

Jenkins 容器启动成功后，可以打开浏览器访问 8080 端口，查看 Jenkins 管理界面：

![image-20220903161247398](.\image\11-docker-jenkins-index.png)

目前运行的容器中，数据会存储在工作目录 /var/jenkins_ home 中，这包括 Jenkins 中所 有的数据，如插件和配置信息等。如果需要数据持久化，读者可以使用数据卷机制：

```shell
[root@192 jenkins]# docker run -p 8080:8080 -p 50000:50000 -v /root/dokcer/jenkins/jenkins_home:/var/jenkins_home jenkins/jenkins
```

## 2. GitLab 及其官方惊醒

GitLab 是一款非常强大的开源源码管理系统。它支持基于 Git 的源码管理、代码评审、 issue 跟踪、活动管理、 wiki页面、持续集成和测试等功能。基于GitLab, 用户可以自己搭建一套类似于 Github 的开发协同 平台。

GitLab 官方提供了社区版本 (GitLab CE) DockerHub 镜像，可以直接使用 docker run  指令运行：

```shell
docker run -d --hostname gitlab.example.com -p 443:443 -p 80:80 -p 23:23 --name gitlab --restart always --volume /srv/gitlab/config:/etc/gitlab --volume /srv/gitlab/logs:/var/log/gitlab --volume /srv/gitlab/data:/var/opt/gitlab gitlab/gitlab-ce:latest
```

成功运行镜像后，可以打开浏览器访问 GitLab 服务管理界面

```shell
# 登录需要账号和密码。默认账号root
# 密码进入宿主机中查看
root@gitlab:/# cat /etc/gitlab/initial_root_password
# WARNING: This value is valid only in the following conditions
#          1. If provided manually (either via `GITLAB_ROOT_PASSWORD` environment variable or via `gitlab_rails['initial_root_password']` setting in `gitlab.rb`, it was provided before database was seeded for the first time (usually, the first reconfigure run).
#          2. Password hasn't been changed manually, either via UI or via command line.
#
#          If the password shown here doesn't work, you must reset the admin password following https://docs.gitlab.com/ee/security/reset_user_password.html#reset-your-root-password.

Password: P28O8sQcdF4OpIsJNycDciEQRyk35ftMUXEazLL+G4Q=

# NOTE: This file will be automatically deleted in the first reconfigure run after 24 hours.
```

![image-20220903164208974](.\image\11-docker-gitlab.png)

## 3. 相关资源

Jenkins 的相关资源如下：

- Jenkins 官网： https://jenkins.io/
- Jenkins 官方仓库： https://github.com/jenkinsci/jenkins/
- Jenkins 官方镜像： https://huh.docker.com/r/jenkinsci/jenkins/
- Jenkins 官方镜像仓库： https://github.com/jenkinsci/docker 

GitLab 的相关资源如下：

- GitLab 官网： https://github.com/gitlabhq/gitlabhq
- GitLab 官方镜像： https://hub.docker.com/r/gitlab/gitlab-ce/

# 11.7 本章小结

本章首先介绍了常见的 Web 服务工具，包括 Apache、Nginx、Tomcat、Jetty, 以及大名 鼎鼎的 LAMP 组合，然后对目前流行的持续开发模式和工具的快速部署进行了讲解。通过这些例子，读者可以快速入门 Web 开发，并再次体验到基于容器模式的开发和部署模式为何如此强大。

笔者认为，包括 Web 服务在内的中间件领域十分适合引入容器技术：

- 中间件服务器是除数据库服务器外的主要计算节点，很容易成为性能瓶颈，所以通常 需要大批量部署，而 Docker 对于批量部署有着许多先天的优势；
- 中间件服务器结构清晰，在剥离了配置文件、日志、代码目录之后，容器几乎可以处于零增长状态，这使得容器的迁移和批量部署更加方便；

- 中间件服务器很容易实现集群，在使用硬件的 F5 、软件的 Nginx 等负载均衡后，中 间件服务器集群变得非常容易。
