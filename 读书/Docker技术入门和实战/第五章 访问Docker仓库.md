**仓库 (Repository) 是集中存放镜像的地方，又分公共仓库和私有仓库。** 

有时候容易把仓库与注册服务器 (Registry) 混淆。实际上注册服务器是存放仓库的具 体服务器，一个注册服务器上可以有多个仓库，而每个仓库下面可以有多个镜像。从这方面 来说，仓库可以被认为是一个具体的项目或目录。例如对于仓库地址 private-docker. com/ubuntu 来说， private-docker.com 是注册服务器地址， ubuntu是仓库名。 

在本章中，笔者将分别介绍使用 Docker Hub 官方仓库进行登录、下载等基本操作，以 及使用国内社区提供的仓库下载镜像；最后还将介绍创建和使用私有仓库的基本操作。

# 5.1 Docker Hub 公共镜像市场

Docker Hub Docker 官方提供的最大的公共镜像仓库，目前包括了超过 100 000 的镜 像，地址为 https://hub.docker.com 。大部分对镜像的需求，都可以通过在 Docker Hub 中直接 下载镜像来实现，如图 5-1 所示。

## 1. 登录

可以通过命令行执 docker login 命令来输入用户名 、密码和邮箱来完成注册和登 录。注册成功后，本地用户目录下会自动创建．docker/config.json 文件，保存用户的认证信息。 登录成功的用户可以上传个人制作的镜像到 Docker Hub

## 2. 基本操作

用户无须登录即可通过 docker search 命令来查找官方仓库中的镜像，并利用 docker [image] pull 命令来将它下载到本地。

在镜像的章节（第 章），已经具体介绍了如何使用 docker [image] pull 命令来搜 寻镜像。例如以 centos 为关键词进行搜索：

```shell
[root@192 ~]# docker search centos
NAME                                         DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
centos                                       The official build of CentOS.                   7285      [OK]
kasmweb/centos-7-desktop                     CentOS 7 desktop for Kasm Workspaces            24
couchbase/centos7-systemd                    centos7-systemd images with additional debug…   4                    [OK]
dokken/centos-7                              CentOS 7 image for kitchen-dokken               3
continuumio/centos5_gcc5_base                                                                3
dokken/centos-stream-9                                                                       2
dokken/centos-stream-8                                                                       2
spack/centos7                                CentOS 7 with Spack preinstalled                1
spack/centos6                                CentOS 6 with Spack preinstalled                1
corpusops/centos-bare                        https://github.com/corpusops/docker-images/     0
dokken/centos-6                              CentOS 6 image for kitchen-dokken               0
ustclug/centos                               Official CentOS Image with USTC Mirror          0
...
```

根据是否为官方提供，可将这些镜像资源分为两类：

- 一种是类似于 centos 这样的基础镜像，也称为根镜像。这些镜像是由 Docker 公司 创建、验证、支持、提供，这样的镜像往往使用单个单词作为名字；
- 另一种类型的镜像，比如 kasmweb/centos-7-desktop 镜像，是由 Docker 用户 kasmweb创建并维护的，带有用户名称为前缀，表明是某用户下的某仓库。可以通过 用户名称前缀 "user_name/ 镜像名”来指定使用某个用户提供的镜像。

下载官方 centos  镜像到本地，代码如下所示：

```shell
[root@192 ~]# docker pull centos
Using default tag: latest
latest: Pulling from library/centos
a1d0c7532777: Pull complete
Digest: sha256:a27fd8080b517143cbbbab9dfb7c8571c40d67d534bbdee55bd6c473f432b177
Status: Downloaded newer image for centos:latest
docker.io/library/centos:latest
```

用户也可以在登录后通过 docker push 命令来将本地镜像推送到 Docker Hub。

## 3. 自动创建

自动创建 (Automated Builds) Docker Hub 提供的自动化服务，这一功能可以自动跟 随项目代码的变更而重新构建镜像。

例如，用户构建了某应用镜像，如果应用发布新版本，用户需要手动更新镜像。而自动 创建则允许用户通过 Docker Hub 指定跟踪一个目标网站（目前支持 GitHub 或 BitBucket) 的项目，一旦项目发生新的提交，则自动执行创建。

要配置自动创建，包括如下的步骤：

1) 创建并登录Docker Hub, 以及目标网站如 Github; 

2) 在目标网站中允许 Docker Hub 访问服务； 
3) Docker Hub 中配置一个“自动创建“类型的项目；
4) 选取一个目标网站中的项目（需要含 Dockerfile) 和分支； 
5) 指定 Dockerfile 的位置，并提交创建。 

之后，可以在 Docker Hub 的“自动创建“页面中跟踪每次创建的状态。

# 5.2 第三方镜像市场

国内不少云服务商都提供了 Docker 镜像市场，包括腾讯云、网易云、阿里云等。下面 以时速云为例，介绍如何使用这些市场，如图 5-2 所示。

## 1. 查看镜像

[[容器镜像服务 (aliyun.com)](https://cr.console.aliyun.com/cn-hangzhou/instances/images)](https://developer.aliyun.com/mirror/)

[腾讯软件源 (tencent.com)](https://mirrors.cloud.tencent.com/)

![image-20220820154150174](.\image\image-20220820152454447.png)

## 2. 使用阿里云镜像加速器

[容器镜像服务 (aliyun.com)](https://cr.console.aliyun.com/cn-hangzhou/instances/mirrors)

## 1. 安装／升级Docker客户端

推荐安装1.10.0以上版本的Docker客户端，参考文档[docker-ce](https://yq.aliyun.com/articles/110806)

## 2. 配置镜像加速器

针对Docker客户端版本大于 1.10.0 的用户

您可以通过修改daemon配置文件/etc/docker/daemon.json来使用加速器

```shell
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://9fgss2yh.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

然后下载镜像，下载镜像会快些

# 5.3 搭建本地私有仓库

## 1.使用 registry 镜像创建私有仓库

安装 Docker 后，可以通过官方提供的 registry 镜像来简单搭建一套本地私有仓库环境：

```shell
$ docker run -d -p 5000:5000 registry:2
```

这将自动下载并启动一个 registry 容器，创建本地的私有仓库服务。 

默认情况下，仓库会被创建在容器的 /var/lib/registry 目录下。可以通过－ 参数来将镜 像文件存放在本地的指定路径。例如下面的例子将上传的镜像放到／opt/data/registry 目录：

```shell
[root@192 ~]# docker run -d -p 5000:5000 -v /opt/data/registry:/var/lib/registry registry:2
a7a84a2be39f344d1974f7a3aa005ca2d568f6c372664add9e32ca7302ebf0f8
```

此时，在本地将启动一个私有仓库服务，监听端口为5000

## 2. 管理私有仓库

我的机器是 centos 搭建私有仓库，其ip地址为 192.168.245.129: 5000，然后再这台机器上测试上传和下载镜像

查看机器上已有的镜像

```shell
[root@192 ~]# docker images
REPOSITORY               TAG       IMAGE ID       CREATED         SIZE
ubuntu                   latest    df5de72bdb3b   2 weeks ago     77.8MB
```

使用docker tag 命令将这个镜像标记为 192.168.245.129:5000/test

```shell
[root@192 ~]# docker tag ubuntu:latest 192.168.245.129:5000/test
```

修改daemon.json 配置文件，加上 insecure-registries

```json
{
    "insecure-registries":["192.168.245.129:5000"],
    "registry-mirrors": ["https://9fgss2yh.mirror.aliyuncs.com"]
}
```

使用 docker push 上传标记的镜像：

```shell
[root@192 registry]# docker push 192.168.245.129:5000/test
Using default tag: latest
The push refers to repository [192.168.245.129:5000/test]
629d9dbab5ed: Pushed
latest: digest: sha256:42ba2dfce475de1113d55602d40af18415897167d47c2045ec7b6d9746ff148f size: 529
```

用curl 查看仓库中的镜像

```shell
[root@192 registry]# curl http://192.168.245.129:5000/v2/_catalog
{"repositories":["test"]}
```

查看刚才设置的仓库地址 /opt/data/registry目录

```shell
[root@192 registry]# pwd
/opt/data/registry
[root@192 registry]# ll
总用量 0
drwxr-xr-x. 3 root root 22 8月  20 16:35 docker
```

多了个docker目录

现在可以到任意一台能访问到 192.168.245.129 地址的机器去下载这个镜像了。

直接下载会报错

```
[root@192 ~]# docker pull 192.168.245.129:5000/test
Using default tag: latest
Error response from daemon: Get "https://192.168.245.129:5000/v2/": http: server gave HTTP response to HTTPS client
```

比较新的 Docker 版本对安全性要求较高，会要求仓库支持 SSL/TLS 证书。对于内部使 用的私有仓库，可以自行配置证书或关闭对仓库的安全性检查。

在 /etc/docker/daemon.json配置文件中加上信任这个地址

```json
{
    "insecure-registries":["192.168.245.129:5000"],  // 信任这个地址
    "registry-mirrors": ["https://9fgss2yh.mirror.aliyuncs.com"]
}
```

再次下载就行了

```shell
[root@192 ~]# docker pull 192.168.245.129:5000/test
Using default tag: latest
latest: Pulling from test
d19f32bd9e41: Pull complete
Digest: sha256:42ba2dfce475de1113d55602d40af18415897167d47c2045ec7b6d9746ff148f
Status: Downloaded newer image for 192.168.245.129:5000/test:latest
192.168.245.129:5000/test:latest
```

提示;

> 如果要使用安全证书，用户也可以从较知名的 CA 服务商（如 verisign) 申请公开的 SSL/TLS 证书，或者使用 OpenSSL 等软件来自行生成。

**除了官方的 registry 项目外，用户还可以使用其他的开源方案（例如 nexus) 来搭建私 有化的容器镜像仓库。**