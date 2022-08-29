很多时候，系统管理员都习惯通过 SSH 服务来远程登录管理服务器，但是 Docker 的很 多镜像是不带 SSH 服务的，那么用户 怎样才能管理容器呢？ 

在第一部分中介绍了一些进入容器的办法，比如用 attach 和 exec  等命令，但是这些 命令都无法解决远程管理容器的问题。因此，当读者需要远程登录到容器内进行一些操作的 时候，就需要 SSH 的支持了。 

本章将具体介绍如何自行创建一个带有 SSH 服务的镜像，并详细介绍了两种创建容器的 方法：基于 docker commit 命令创建和基于 Dockerfile 创建。

# 10.1 基于commit命令创建

Docker 提供了 docker commit 命令，支持用户提交自己对制定容器的修改，并生成 新的镜像。命令格式为 docker commit CONTAINER: [REPOSITORY [: TAG] ]。

这里介绍如何使用docker commit 命令为ubuntu:18.04镜像添加SSH服务

## 1. 准备工作

首先，获取 ubuntu:18.04 镜像，并创建一个容器：

```shell
[root@192 ~]# docker pull ubuntu:18.04
[root@192 ~]# docker run -it ubuntu:18.04 bash
root@76937ed2c1fe:/#

```

## 2. 配置软件源

检查软件源，并使用 apt-get update 命令来更新软件源信息：

```shell
root@76937ed2c1fe:/# apt-get update
```

## 3. 安装和配置 SSH 服务

更新软件包缓存后可以安装 SSH 服务了，选择主流的 openssh-server 作为服务端。可以 看到需要下载安装众多的依赖软件包：

```shell
root@76937ed2c1fe:/# apt-get update install openssh-server
```

如果需要正常启动 SSH 服务，则目录/var/run/sshd 必须存在。下面手动创建它，并启动 SSH 服务：

```shell
root@76937ed2c1fe:/# mkdir -p /var/run/sshd
root@76937ed2c1fe:/# /usr/sbin/sshd -D &
[1] 3906
```

此时查看容器的 22 端口 (SSH 服务默认监听的端口），可见此端口已经处于监听状态：

```shell
# 如果netstat 命令不存在，则执行 apt install net-tools
root@76937ed2c1fe:/# netstat -tunlp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      3906/sshd
tcp6       0      0 :::22                   :::*                    LISTEN      3906/sshd
```

设置一个root密码，后面登陆会用到

```shell
root@76937ed2c1fe:/# passwd
```

修改配置文件

```shell
root@76937ed2c1fe:/# vim /etc/ssh/sshd_config

#注释这一行PermitRootLogin prohibit-password
# 添加一行PermitRootLogin yes

#PermitRootLogin prohibit-password
PermitRootLogin yes
```

创建自动启动 SSH 服务的可执行文件 run.sh, 并添加可执行权限：

```shell
root@76937ed2c1fe:/# vi /run.sh 
root@76937ed2c1fe:/# chmod +x run.sh 

# run.sh 脚本内容如下：
#!/bin/bash 
/usr/sbin/sshd -D

# 最后，退出容器：
root@76937ed2c1fe:/# exit
exit
```

## 4. 保存镜像

将所退出的容器用docker commit 命令保存为一个新的 sshd:ubuntu 镜像。

```shell
[root@192 /]# docker commit 76937ed2c1fe sshd:ubuntu
sha256:50484d203fbb9dd674c95f7ddc3ffe3ede73c422201a43fea51944bb1e0183f5
```

使用 docker images 查看本地生成的新镜像 ~shd:ubuntu, 目前拥有的镜像如下：

```shell
[root@192 /]# docker images
REPOSITORY                  TAG       IMAGE ID       CREATED          SIZE
sshd                        ubuntu    50484d203fbb   35 seconds ago   257M
```

## 5. 使用镜像

启动容器，并添加端口映射 10022 -->22 。其中 10022 是宿主主机的端口， 22 是容 器的 SSH 服务监听端口：

```shell
[root@192 /]# docker run -p 10022:22 -d sshd:ubuntu /run.sh
90d4acf03acf1df076c4af82d453f6d5df1bf8730d985d5dc1d3a9beeab52310
```

启动成功后，可以在宿主主机上看到容器运行的详细信息。

```shell
[root@192 /]# docker ps
CONTAINER ID   IMAGE          COMMAND     CREATED          STATUS          PORTS                                     NAMES
90d4acf03acf   sshd:ubuntu    "/run.sh"   7 seconds ago    Up 5 seconds    0.0.0.0:10022->22/tcp, :::10022->22/tcp   sharp_greider
18f30ebaa701   ubuntu:18.04   "bash"      34 minutes ago   Up 34 minutes                                             my_ubuntu
```

在宿主主机 (192.168.245.129) 或其他主机上上，可以通过 SSH 访问 10022 端口来登录 容器：

```shell
[root@192 /]# ssh 192.168.245.129 -p 10022
root@192.168.245.129's password:
Welcome to Ubuntu 18.04.6 LTS (GNU/Linux 3.10.0-1160.66.1.el7.x86_64 x86_64)

```

# 10.2 使用 Dockerfile 创建

## 1. 创建工作目录

```shell
# 首先，创建一个 sshd_ubuntu 工作目录：
[root@192 dokcer]# mkdir sshd_ubuntu
[root@192 dokcer]#

# 在其中，创建 Dockerfile run.sh 文件：
[root@192 dokcer]# cd sshd_ubuntu/
[root@192 dokcer]# mkdir sshd_ubuntu
[root@192 dokcer]# cd sshd_ubuntu/
[root@192 sshd_ubuntu]# touch Dockerfile run.sh
[root@192 sshd_ubuntu]# ls
Dockerfile  run.sh
```

## 2. 编写 run.sh 脚本

脚本文件 run.sh 的内容与上一小节中一致：

```shell
#!/bin/bash 
/usr/sbin/sshd -D 
```

在宿主主机上生成 SSH 密钥对，并创建 authorized_keys 文件：

```shell
[root@192 dokcer]# ssh-keygen -t rsa
[root@192 dokcer]# cat ~/.ssh/id_rsa.pub > authorized_keys
```

## 3. 编写 Dockerfile

```dockerfile
# 设置继承镜像
FROM ubuntu:18.04

# 提供作者的信息
MAINTAINER docker_user(1583409404@qq.com)

# 下面开始运行命令，此处更改 ubun 的源为国内 16,3 的源
RUN echo "deb http://mirrors.163.com/ubuntu/ bionic main restricted universe multiverse" > /etc/apt/sources.list 
RUN echo "deb http://mirrors.163.com/ubuntu/ bionic-security main restricted universe multiverse" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.163.com/ubuntu/ bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.163.com/ubuntu/ bionic-proposed main restricted universe multiverse" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.163.com/ubuntu/ bionic-backports main restricted universe multiverse" >> /etc/apt/sources.list

RUN apt-get update

RUN apt-get install -y openssh-server
RUN mkdir -p /var/run/sshd 
RUN mkdir -p /root/.ssh
# 取消 pam 限制
RUN sed -ri 's/ session required pam_loginuid.so/#session required pam_loginuid.so/g' /etc/pam.d/sshd

# 复制配置文件到相应位置，并赋予脚本可执行权限

ADD authorized_keys /root/.ssh/authorized_keys
ADD run.sh /run.sh 
RUN chmod 755 /run.sh

# 开放端口
EXPOSE 22 
# 设置自启动命令
CMD ["/run.sh"] 
```

## 4. 创建镜像

在sshd_ubuntu 目录下，使用 docker build 命令来创建镜像。这里用户需要注意 在最后还有一个“. "，表示使用当前目录中的 Dockerfile : 

```shell
$ cd sshd_ubuntu
$ docker build -t sshd:dockerfile . 
...
Successfully built a866b77755bc
Successfully tagged sshd:dockerfile
```

如果读者使用 Dockerfile 创建自定义镜像，那么需要注意的是 Docker 会自动删除中间临 时创建的层，还需要注意每一步的操作和编写的 Dockerfile 中命令的对应关系。

命令执行完毕后，如果读者看见 "Successfully built XXX" 字样，则说明镜像创建成功。 可以看到，以上命令生成的镜像 ID a866b77755bc

在本地查看 sshd:dockerfile 镜像已存在：

```shell
[root@192 sshd_ubuntu]# docker images
REPOSITORY                  TAG          IMAGE ID       CREATED             SIZE
sshd                        dockerfile   a866b77755bc   2 minutes ago       221MB
```

## 5. 测试镜像，运行容器

下面使用刚才创建的 sshd:dockerfile 镜像来运行一个容器。 直接启动镜像，映射容器的 22 端口到本地的 10122 端口：

```shell
[root@192 sshd_ubuntu]# docker run -it -d -p 10122:22 sshd:dockerfile
50c8aa028c4cdd6f5a8057b58429990084f3f85acb552b6655799c29d46ddcac
[root@192 sshd_ubuntu]# docker ps
CONTAINER ID   IMAGE             COMMAND     CREATED          STATUS          PORTS                                     NAMES
50c8aa028c4c   sshd:dockerfile   "/run.sh"   3 seconds ago    Up 2 seconds    0.0.0.0:10122->22/tcp, :::10122->22/tcp   fervent_nobel
```

在宿主主机新打开一个终端，连接到新建的容器：（**这里没有密码，设置密码参考10.1**）

```shell
[root@192 sshd_ubuntu]# ssh 192.168.245.129 -p 10122
The authenticity of host '[192.168.245.129]:10122 ([192.168.245.129]:10122)' can't be established.
ECDSA key fingerprint is SHA256:j33O75x+cRlD5EPJA5a1GCCndBGjjn5DKAjtqxn4aMA.
ECDSA key fingerprint is MD5:62:bc:85:1b:a4:99:b6:32:8c:50:41:8e:24:65:d7:36.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '[192.168.245.129]:10122' (ECDSA) to the list of known hosts.
Welcome to Ubuntu 18.04.6 LTS (GNU/Linux 3.10.0-1160.66.1.el7.x86_64 x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.

The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

root@50c8aa028c4c:~#
```

# 10.3 本章小结

在Docker 社区中，对于是否需要为 Docker 容器启用 SSH 服务一直有争论。 

一方的观点是： Docker 的理念是一个容器只运行一个服务。因此，如果每个容器都运行 一个额外的 SSH 服务，就违背了这个理念。而且认为根本没有从远程主机进入容器进行维护 的必要。 

另外一方的观点是：虽然使用 docker exec 命令可以从本地进入容器，但是如果要从 其他远程主机进入依然没有更好的解决方案。

笔者认为，这两种说法各有道理，其实是在讨论不同的容器场景：作为应用容器，还是作为系统容器。应用容器行为围绕应用生命周期，较为简单，不需要人工的额外干预；而系统容器则需要支持管理员的登录操作，这个时候，对 SSH 服务的支持就变得十分必要了。

因此，在Docker 推出更加高效、安全的方式对系统容器进行远程操作之前，容器的 SSH 服务还是比较重要的，而且它对资源的需求不高，同时安全性可以保障。
