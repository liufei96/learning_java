Dockerfile 是一个文本格式的配置文件，用户可以使用 Dockerfile 来快速创建自定义的镜像。 

本章首先将介绍 Dockerfile 典型的基本结构及其支持的众多指令，并具体讲解通过这些 指令来编写定制镜像的 Dockerfile, 以及如何生成镜像。最后，会介绍使用 Dockerfile 的一些 最佳实践经验。

# 8.1 基本结构

Dockerfile 由一行行命令语句组成，并且支持以＃开头的注释行。

下面给出一个简单的示例：

```dockerfile
# escape=\ (backslash) 
# This dockerfile uses the ubuntu:xeniel image 
# VERSION 2 - EDITION 1 
# Author: docker_user 
# Command format: Ins ruc ion [arguments / command] 

# Base image use, this must be se as he first line 
FROM ubuntu:xeniel 

# Main ainer: docker user <docker user email.com> (@docker _user) 
LABEL maintainer docker user<docker user@email.com>

# Commands update the image 
RUN echo "deb http://archive.ubuntu.com/ubuntu/ xeniel main universe" >> /etc/apt/sources.list


RUN apt-get update && apt-get install -y nginx 
RUN echo "\ndaemon off;">> /etc/nginx/nginx.conf

# Commands when crea ing a new con ainer
CMD /usr/sbin/nginx
```

首行可以通过注释来指定解析器命令，后续通过注释说明镜像的相关信息。主体部分首 先使用 FROM 指令指明所基于的镜像名称，接下来一般是使用 LABEL 指令说明维护者信息。 后面则是镜像操作指令，例如 RUN 指令将对镜像执行跟随的命令。每运行一条 RUN 指令， 镜像添加新的一层，并提交。最后是 CMD 指令，来指定运行容器时的操作命令。

下面是 Docker Hub 上两个热门镜像 nginx 和 Go Dockerfile 的例子，通过这两个例 子。读者可以对 Dockerfile 结构有个基本的感知。

第一个是在 debian:jessie 基础镜像基础上安装 Nginx 环境，从而创建一个新的 nginx 镜像：

```dockerfile
FROM debian:jessie 
LABEL maintainer docker_user<docker_user@email.com> 

ENV NGINX_VERSION 1.10.1-1-jessie 

RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC64107 
	9A6ABABFSBD827BD9BF62 \ 
		&& echo "deb http://nginx.org/packages/debian/ jessie nginx" >> /etc/
		apt/sources.list ＼
		&& apt-get update \ 
		&& apt-get install --no-install-recommends --no-install-suggests -y \ 
		ca-certificates \
		nginx=${NGINX_VERSION} \ 
		nginx-module-xslt ＼
		nginx-module-geoip \ 
		nginx-module-image-filter \
		nginx-module-perl \ 
		nginx-module-njs \ 
		gettext-base \ 
			&& rm -rf /var/lib/apt/lists/*
# forward reques and error logs to docker log collector 
RUN ln -sf /dev/stdout /var/log/nginx/access.log \ 
	&& ln -sf /dev/stderr /var/log/nginx/error.log 

EXPOSE 80 443 

CMD ["nginx", "-g", "daemon off;")
```

第二个是基于 buildpack-deps:jessie-scm 基础镜像，安装 Golang 相关环境，制 作一个 Go 语言的运行环境镜像：

```dockerfile
FROM buildpack-deps:jessie-scm 
# gee for ego 

RUN apt-get update && apt-get install -y --no-install-recommends \
	g++ \ 
	gcc \ 
	libc6-dev \ 
	make\ 
	&& rm -rf /var/lib/apt/lists/* 

ENV GOLANG VERSION 1.6.3 
ENV GOLANG_DOWNLOAD_URL https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOLANG DOWNLOAD.SHA256 cdde5e08530c0579255d6153b08fdb3b8e47caabbe717bc7bcd75 
61275a87aeb 

RUN curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \ 
	&& echo " $GOLANG _DOWNLOAD_ SHA256 golang.tar.gz" | sha256sum -c - \ 
    && tar -c /usr/local -xzf golang.tar.gz \ 
	&& rm golang.tar.gz 

ENV GOPATH /go 
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH 
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH" 
WORKD $GOPATH 

COPY go-wrapper /usr/local/bin/
```

下而，将讲解 Dockerfile 中各种指令的应用。

# 8.2 指令说明

Dockerfile 中指令的一般格式为 INSTRUCT ON arguments, 包括“配置指令＂ （配置 镜像信息）和“操作指令＂（具体执行操作），参见表 8-1。

表8-1 Dockerfile中的指令及说明

| 分类     | 指令        | 说明                               |
| -------- | ----------- | ---------------------------------- |
| 配置指令 | ARG         | 定义创建镜像过程中使用的变量       |
|          | FROM        | 指定所创建镜像的基础镜像           |
|          | LABEL       | 为生成的镜像添加元数据标签信息     |
|          | EXPOSE      | 声明镜像内服务监听的端口           |
|          | ENV         | 指定环境变最                       |
|          | ENTRYPOINT  | 指定镜像的默认入口命令             |
|          | VOLUME      | 创建一个数据卷挂载点               |
|          | USER        | 指定运行容器时的用户名或 UID       |
|          | WORDIR      | 配置工作目录                       |
|          | ONBUILD     | 创建子镜像时指定自动执行的操作指令 |
|          | STOPSIGNAL  | 指定退出的信号值                   |
|          | HEALTHCHECK | 配置所启动容器如何进行健康检查     |
|          | SHELL       | 指定默认 shell 类型                |
| 操作指令 | RUN         | 运行指定命令                       |
|          | CMD         | 启动容器时指定默认执行的命令       |
|          | ADD         | 添加内容到镜像                     |
|          | COPY        | 复制内容到镜像                     |

## 8.2.1 配置指令

###  1. ARG

定义创建镜像过程中使用的变量。

格式为ARG <name>[=<default value]。

在执行docker build时，可以通过 -build-arg[=] 来为变量赋值。当镜像编译成功后，ARG 指定的变量将不再存在（ENV指定的变量将在镜像钟保留）。

Docker 内置了一些镜像创建变量，用户可以直接使用而无须声明，包括（不区分大小 写） HTTP_PROXY、HTTPS_PROXY、 FTP_PROXY、NO_PROXY。

### 2. FROM 

指定所创建镜像的基础镜像。

格式为 FROM <image> [AS <name>] 或 FROM <image>:<tag> [AS <name>] 或 FROM <image>@<digest> [AS <name>]。

任何 Dockerfile 中第一条指令必须为 FROM 指令。并且，如果在同一个 Dockerfile 中创 建多个镜像时，可以使用多个 FROM 指令（每个镜像一次）。

为了保证镜像精简，可以选用体积较小的镜像如 Alpine 或 Debian 作为基础镜像。例如：

```dockerfile
ARG VERSION=0.3
FROM debian:${VERSION}
```

### 3. LABEL

LABEL 指令可以为生成的镜像添加元数据标签信息。这些信息可以用来辅助过滤出特 定镜像。

格式为 LABEL <key>=<value> <key>=<value> <key>=<value>...。

 例如： 

```dockerfile
version="1.0.0-rc3"
LABEL author="liufei96@github" date="2022-08-24" 
LABEL description="This text illustrates\
	that label-values can span multiple lines."
```

### 4. EXPOSE

声明镜像内服务监听的端口。

格式为 EXPOSE <port> [<port>/<protocol>... ]。

例如：

```docker
EXPOSE 22 80 8443
```

**注意该指令只是起到声明作用，并不会自动完成端口映射。** 

如果要映射端口出来，在启动容器时可以使用 -P 参数 (Docker 主机会自动分配一个宿主机的临时端口）或 -p HOST_PORT:CONTAINER_PORT 参数（具体指定所映射的本地端口）。

### 5. ENV

指定环境变量，在镜像生成过程中会被后续 RUN 指令使用，在镜像启动的容器中也会存在。

格式为 ENV   <key> <value> 或 ENV <key>=<value> ...。

例如：

```dockerfile
ENV APP_VERSION=1.0.0
ENV APP_HOME=/usr/local/app
ENV PATH:$PATH:/usr/local/bin
```

指令指定的环境变量在运行时可以被覆盖掉，如 docker run --env  <key>=<value>  built＿ image。

**注意当一条 ENV 指令中同时为多个环境变量赋值并且值也是从环境变量读取时，会为 变量都赋值后再更新。**

如下面的指令，最终结果为 key1=value1 key2=value2:

```dockerfile
ENV key1=value2
ENV key1=value1 key2=${key1}
```

### 6. ENTRYPOINT

指定镜像的默认入口命令，该入口命令会在启动容器时作为根命令执行，所有传人值作 为该命令的参数。

支持两种格式：

- ENTRYPOINT["executable", "param1", "param2"]: exec 调用执行;
- ENTRYPOINT command param1 param2: shell中执行

此时， CMD 指令指定值将作为根命令的参数。 每个 Dockerfile 中只能有一个 ENTRYPOINT, 当指定多个时，只有最后一个起效。

在运行时，可以被--entrypoint参数覆盖掉，如 docker run --entrypoint。

### 7. VOLUME

创建一个数据卷挂载点。

格式为 VOLUME ["/data"] 

运行容器时可以从本地主机或其他容器挂载数据卷，一般用来存放数据库和需要保持的数据等。

### 8. USER

指定运行容器时的用户名或 UID, 后续的 RUN 等指令也会使用指定的用户身份。

格式为 USER daemon。

当服务不需要管理员权限时，可以通过该命令指定运行用户，并且可以在 Dockerfile 创建所需要的用户。

例如：

```dockerfile
RUN groupadd -r postgres && useradd --no-log-init -r -g postgres postgres
```

要临时获取管理员权限可以使用 gosu 命令。

### 9. WORKDIR 

为后续的 RUN、CMD、ENTRYPOINT 指令配置工作目录。

格式为 WORKDIR  /path/to/workdir。

可以使用多个 WORKDIR 指令，后续命令如果参数是相对路径，则会基于之前命令指定 的路径。例如：

```dockerfile
WORKDIR /a
WORKDIR b
WORKDIR c
RUN pwd
```

则最终路径为 /a/b/c

因此，为了避免出错，推荐 WORKD 指令中只使用绝对路径。

### 10. ONBUILD

指定当基于所生成镜像创建子镜像时，自动执行的操作指令。