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

格式为 ONBUILD [ INSTRUCTION]。

例如，使用如下的 Dockerfile 创建父镜像 ParenImage, 指定 ONBUILD 指令：

```dockerfile
# Dockerfile for Paren七工 mage
[...] 
ONBUILD ADD . /app/src 
ONBUILD RUN /usr/local/bin/python-build --dir /app/src 
[...] 
```

使用 docker build 命令创建子镜像 ChildImage (FROM ParenImage) ，会首 先执行 FarentImage 中配置的 ONBUILD 指令：

```dockerfile
# Dockerfile from ChildImage
FROM ParentImage
```

等价于在 ChildImage Dockerfile 中添加了如下指令：

```dockerfile
#Automa ically run he following when building Childimage 
ADD . /app/src
RUN /usr/local/bin/python-build --dir /app/src
...
```

由于 ONBUILD 指令是隐式执行的，推荐在使用它的镜像标签中进行标注，例如ruby:2.1- onbuild

**ONBUILD 指令在创建专门用于自动编译、检查等操作的基础镜像时，十分有用。**

### 11. STOPSINGAL

指定所创建镜像启动的容器接收退出的信号值：

STOPSIGNAL signal

### 12. HEALTHCHECK

配置所启动容器如何进行健康检查（如何判断健康与否），自 Docker 1.12 开始支持。

格式有两种：

- HEALTHCHECK [OPTIONS] CMD command：根据所执行命令返回值是否为0来判断；
- HEALTHCHECK NONE：禁止基础镜像中的健康检查。

OPTION支持如下参数：

- -interval=DURATION（default：30s）：过多久检查一次；
- -timeout=DURATION（default：30s）：每次检查等待结果的超时；
- -retries=N (defaut: 3) ：如果失败了，重试几次才最终确定失败。

### 13. SHELL

指定其他命令使用 shell 时的默认 shell 类型：

```dockerfile
SHELL  ["executable",  "parameters"]
```

默认值为 ["bin/bash",  "-c"]

注意：对于 Windows 系统， Shel1 路径中使用了“\”作为分隔符，建议在 Dockerfile 开头添 加＃escape=‘ 来指定转义符。

## 8.2.2 操作指令

### 1. RUN

运行指定命令。

格式为 RUN < command> 或 RUN ["executable", "paraml", "param2"] 。注 意后者指令会被解析为 JSON 数组，因此必须用双引号。前者默认将在 shell 终端中运行命 令，即／bin/sh -c ；后者则使用 exec 执行，不会启动 shell 环境。

指定使用其他终端类型可以通过第二种方式实现，例如 RUN

```dockerfile
RUN ["/bin/bash", "-c", "echo hello"]
```

每条 RUN 指令将在当前镜像基础上执行指定命令，并提交为新的镜像层。当命令较长时 可以使用＼来换行。例如：

```dockerfile
RUN apt-get update \
	&& apt-get install -y zliblg-dev libbz2-dev \
	&& rm -rf /var/cache/apt \
	&& rm -rf /var/lib/apt/lists*/
```

### 2. CMD

CMD 指令用来指定启动容器时默认执行的命令。

支持三种格式：

- CMD ["executable", "param1", "param2"]：相当于执行executable param1 param2，推荐方式；
- CMD command param1 param2：在默认的Shell中执行，提供给需要交换的应用；
- CMD ["param1", "param2"]：提供给ENTRYPOINT的默认参数。

**每个 Dockerfile 只能有一条 CMD 命令。如果指定了多条命令，只有最后一条会被执行。**

如果用户启动容器时候手动指定了运行的命令（作为 run 命令的参数），则会覆盖掉 CMD 指定的命令。

### 3. ADD

添加内容到镜像。 

格式为 ADD  <src> <dest>。

该命令将复制指定的 <src> 路径下内容到容器中的 <dest> 路径下。

其中 <src> 可以是Dockerfile 所在目录的一个相对路径（文件或目录）；也可以是一个 URL ；还可以是一个tar文件（自动解压为目录） <dest> 可以是镜像内绝对路径，或者相 对于工作目录 (WORKDIR) 的相对路径。

路径支持正则格式，例如：

```dockerfile
ADD  *.c /code/
```

### 4. COPY

复制内容到镜像。

格式为CPOPY <src> <dest>。

复制本地主机的  <src>（为 Dockerfile 所在目录的相对路径，文件或目录）下内容到镜 像中的 <dest>。目标路径不存在时，会自动创建。

路径同样支持正则格式。

COPY 与 ADD 指令功能类似，当使用本地目录为源目录时，推荐使用 COPY。

# 8.3 创建镜像

编写完成 Dockerfile 之后，可以通过 docker [image] build 命令来创建镜像。

基本的格式为 docker build [OPTIONS]  PATH I URL －。

该命令将读取指定路径下（包括子目录）的 Dockerfile, 并将该路径下所有数据作为上下文 (Context) 发送给 Docker 服务端。 Docker 服务端在校验 Dockerfile 格式通过后，逐条执行 其中定义的指令，碰到 ADD、COPY 、RUN 指令会生成一层新的镜像。最终如果创建镜像成功，会返回最终镜像的ID。

如果上下文过大，会导致发送大量数据给服务端，延缓创建过程。因此除非是生成镜像 所必需的文件，不然不要放到上下文路径下。如果使用非上下文路径下的 Dockerfile, 可以 通过 -f 选项来指定其路径。

要指定生成镜像的标签信息，可以通过-t 选项。该选项可以重复使用多次为镜像一次添 加多个名称。

例如，上下文路径为 /tmp/docker_ builder/ ，并且希望生成镜像标签为 builder/first_image: 1.0.0,  可以使用下面的命令：

```dockerfile
$ docker build -t builder/first_image:1.0.0 /tmp/docker_builder/
```

## 8.3. 1 命令选项

docker [image] build 命令支持一系列的选项，可以调整创建镜像过程的行为，参 见表 8-2

| 选项                   | 说明                                     |
| ---------------------- | ---------------------------------------- |
| --add-host list        | 添加自定义的主机名到 IP 的映射           |
| -build-arg list        | 添加创建时的变量                         |
| -cache-from strings    | 使用指定镜像作为缓存源                   |
| -cgroup-parent string  | 继承的上层 cgroup                        |
| -compress              | 使用 gzip 来压缩创建上下文数据           |
| -cpu-period int        | 分配的 CFS 调度器时长                    |
| -cpu-quo int           | CFS 调度器总份额                         |
| -c, -cpu-shares int    | CPU 权重                                 |
| -cpuset-cpus string    | 多CPU允许使用CPU                         |
| -cpuset-mems string    | 多CPU 允许使用的内存                     |
| -disable-content-trust | 不进行镜像校验，默认为真                 |
| -f, -files string      | Dockerfile名称                           |
| -force-rm              | 总是删除中间过程的容器                   |
| -iidfile string        | 将镜像 ID 写入到文件                     |
| -isolations string     | 容器的隔离机制                           |
| -label list            | 配置镜像的元数据                         |
| -m, -memory bytes      | 限制使用内存量                           |
| -memory-swap bytes     | 限制内存和缓存的总批                     |
| -networks string       | 指定 RUN 命令时的网络模式                |
| -no-cache              | 创建镜像时不适用缓存                     |
| -platforms string      | 指定平台类型                             |
| -pull                  | 总是尝试获取镜像的最新版本               |
| -q, -quiet             | 不打印创建过程中的日志信息               |
| -rm                    | 创建成功后自动删除中间过程容器，默认为真 |
| -security-opt strings  | 指定安全相关的选项                       |
| -shm-size bytes        | /dev/shm 的大小                          |
| -stream                | 持续获取创建的上下文                     |
| -t, -tag list          | 指定镜像的标签列表                       |
| -target string         | 指定创建的目标阶段                       |
| -ulimit ulimit         | 指定 ulimt的配置                         |

## 8.3.2 选择父镜像

大部分情况下，生成新的镜像都需要通过 FROM 指令来指定父镜像。父镜像是生成镜像 的基础，会直接影响到所生成镜像的大小和功能。

用户可以选择两种镜像作为父镜像，一种是所谓的基础镜像 (baseimage) ，另外一种是 普通的镜像（往往由第三方创建，基千基础镜像）。

基础镜像比较特殊，其 Dockerfile 中往往不存在 FROM 指令，或者基于 scratch 镜像 (FROM scratch) ，这意味着其在整个镜像树中处于根的位置。

下面的 Dockerfile 定义了一个简单的基础镜像，将用户提前编译好的二进制可执行文件 binary 复制到镜像中，运行容器时执行 binary 命令：

```dockerfile
FROM scratch
ADD binary /
CMD ["/binary"]
```

普通镜像也可以作为父镜像来使用，包括常见的 busybox debian ubuntu 等。 Docker 不同类型镜像之间的继承关系如图 8-1 所示。

## 8.3.3 使用.dockerignore 文件

可以通过.dockerignore 文件（每一行添加一条匹配模式）来让 Docker 忽略匹配路 径或文件，在创建镜像时候不将无关数据发送到服务端。

例如下面的例子中包括了 行忽略的模式（第一行为注释）：

```dockerfile
#.dockerignore 文件中可以定义忽略模式
*/temp*
*/*/tmp/*
tmp?
~*
Dockerfile
!README.md
```



- dockerignore 文件中模式语法支持 Golang 风格的路径正则格式：
- “*" 表示任意多个字符;
- ”?” 代表单个字符；
- "!" 表示不匹配（即不忽略指定的路径或文件））

![image-20220826222645387](.\image\image-20220826222645387.png)

## 8.3.4 多步骤创建

自17.05 版本开始， Docker 支持多步骤镜像创建 (Multi-stage build) 特性，可以精简最 终生成的镜像大小。

对于需要编译的应用（如 C、Go 或 Java 语言等）来说，通常情况下至少需要准备两个 环境的 Docker 镜像：

- 编译环境镜像：包括完整的编译引擎、依赖库等，往往比较庞大。作用是编译应用为 二进制文件；
- 运行环境镜像：利用编译好的二进制文件，运行应用，由于不需要编译环境，体积比 较小。

使用多步骤创建，可以在保证最终生成的运行环境镜像保持精简的情况下，使用单一的 Dockerfile, 降低维护复杂度。

以 Go 语言应用为例。创建干净目录，进入到目录中，创建 main.go 文件，内容为：

```go
// main.go will ou put "Hello, Docker" 
package main

import (
	"fmt"
)

func main() {
    fmt.Println("Hello, Docker")
}
```

创建 Dockerfile, 使用 golang:1.9 镜像编译应用二进制文件为 app, 使用精简的镜像 alpine:latest 作为运行环境。 Dockerfile 完整内容为：

```dockerfile
FROM golang:1.9 as builder # defina stage name as builder
RUN mkdir -p /go/src/test
WORKDIR /go/src/test
COPY main.go .
RUN CGO_ENABLED=0 GOOS=linux go build -o app .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /go/src/test/app . # copy file from he builders age
CMD ["./app"]
```

执行如下命令创建镜像，并运行应用：

```shell
[root@192 ~]# docker build -t yeasy/test-multistage:latest .
Sending build context to Docker daemon  226.3MB
Step 1/10 : FROM golang:1.9 as builder
 ---> ef89ef5c42a9
Step 2/10 : RUN mkdir -p /go/src/test
 ---> Using cache
 ---> 39e711fa03f1
Step 3/10 : WORKDIR /go/src/test
 ---> Using cache
 ---> 7d6ea9deb09c
Step 4/10 : COPY main.go .
 ---> Using cache
 ---> 2e624bb32ded
Step 5/10 : RUN CGO_ENABLED=O GOOS=linux go build -o app .
 ---> Using cache
 ---> f1470be330ef
Step 6/10 : FROM alpine:latest
 ---> c059bfaa849c
Step 7/10 : RUN apk --no-cache add ca-certificates
 ---> Using cache
 ---> 1b193492186d
Step 8/10 : WORKDIR /root/
 ---> Using cache
 ---> b4115dc6dc24
Step 9/10 : COPY --from=builder /go/src/test/app .
 ---> 5dd727b163e7
Step 10/10 : CMD ["./app"]
 ---> Running in eaa846171abb
Removing intermediate container eaa846171abb
 ---> c085642da421
Successfully built c085642da421
Successfully tagged yeasy/test-multistage:latest

[root@192 ~]# docker run --rm yeasy/test-multistage:latest
Hello, Docker
```

查看生成的最终镜像，大小只有 7.96MB: 

```shell
[root@192 ~]# docker images | grep yeasy/test-multistage
yeasy/test-multistage       latest    c085642da421   2 minutes ago   7.96MB
```

# 8.4 最佳实践

所谓最佳实践，就是从需求出发，来定制适合自己、高效方便的镜像。 首先，要尽量吃透每个指令的含义和执行效果，多编写一些简单的例子进行测试，弄清 楚了再撰写正式的 Dockerfile 。此外， Docker Hub 官方仓库中提供了大量的优秀镜像和对应 Dockefile, 可以通过阅读它们来学习如何撰写高效的 Dockerfile。

笔者在应用过程中，也总结了一些实践经验。建议读者在生成镜像过程中，尝试从如下 角度进行思考，完善所生成镜像：

- **精简镜像用途**：尽量让每个镜像的用途都比较集中单一，避免构造大而复杂、多功能 的镜像；
- 选用合适的基础镜像：容器的核心是应用。选择过大的父镜像（如 ubuntu系统镜像） 会造成最终生成应用镜像的擁肿，推荐选用瘦身过的应用镜像（如 node:slim) ，或 者较为小巧的系统镜像（如 alpine、busybox 或debian);
- **提供注释和维护者信息**： Dockerfile 也是一种代码，需要考虑方便后续的扩展和他人 的使用；
- **正确使用版本号**：使用明确的版本号信息，如 1.0, 2.0, 而非依赖于默认的 latest。 通过版本号可以避免环境不一致导致的问题；
- 减少镜像层数：如果希望所生成镜像的层数尽批少，则要尽批合并 RUN、ADD、COPY 指令。通常情况下，多个 RUN 指令可以合并为一条 RUN 指令；
- **恰当使用多步骤创建 (17.05 ＋版本支持）**：通过多步骤创建，可以将编译和运行等过程分开，保证最终生成的镜像只包括运行应用所需要的最小化环境。当然，用户也可 以通过分别构造编译镜像和运行镜像来达到类似的结果，但这种方式需要维护多个 Dockerfile
- 使**用 .dockerignore 文件**：使用它可以标记在执行 docker build 时忽略的路径和 文件，避免发送不必要的数据内容，从而加快整个镜像创建过程。
- **及时删除临时文件和缓存文件**：特别是在执行 apt-get 指令后，／var/cache/apt 下面会缓存了一些安装包；
- **提高生成速度**：如合理使用 cache, 减少内容目录下的文件，或使用 .dockerignore  文件指定等；
- **调整合理的指令顺序**：在开启 cache 的情况下，内容不变的指令尽量放在前面，这样 可以尽量复用；
- **减少外部源的干扰**：如果确实要从外部引入数据，需要指定持久的地址，并带版本信 息等，让他人可以复用而不出错。