# 4.1 创建容器

## 1. 新建容器

命令: docker create命令新建一个容器

```shell
[root@192 ~]# docker create -it ubuntu:latest
46d226765327ec8742e5d847a0fcfc95b2cfc56fb35f465090031ca8d802af97


[root@192 ~]# docker ps -a
CONTAINER ID   IMAGE                    COMMAND                  CREATED          STATUS                      PORTS     NAMES
46d226765327   ubuntu:latest            "bash"                   10 seconds ago   Created                               objective_leavitt
```

create 创建出来的容器处于停止状态 ，可以使用docker start 命令启动它

由于容器是整个 Docker 技术栈的核心， create 命令和后续的 run 命令支持的选项都 十分复杂

选项主要包括如下几大类：与**容器运行模式相关**、与**容器环境配置相关**、与**容器资源限制和安全保护相关**，参见表 4-1 ～表 4-3

TODO

其他选项还包括：

- -l, --label=[]：以键值对方式指定容器的标签信息
- --label-file=[]：从文件中读取标签信息

## 2. 启动容器

使用 docker [container] start 命令来启动一个已经创建的容器。例如，启动刚 创建的 ubuntu 容器：

```shell
[root@192 ~]# docker start 46d226765327
46d226765327


[root@192 ~]# docker ps
CONTAINER ID   IMAGE           COMMAND   CREATED         STATUS          PORTS     NAMES
46d226765327   ubuntu:latest   "bash"    8 minutes ago   Up 29 seconds             objective_leavitt
```

## 3. 新建并启动容器

除了创建容器后通过 江命令来启动，也可以直接新建并启动容器。

所需要的命令主要为 docker [container] run, 等价于先执行 docker [container] create 命令，再执行 docker [container] start 命令。 例如，下面的命令输出一个 “Hello World" ，之后容器自动终止：

```shell
[root@192 ~]# docker run ubuntu /bin/echo 'Hello world'
Hello world
```

这跟在本地直接执行／bin/echo 'hello world' 相比几乎感觉不出任何区别。 当利用 docker [container] run 来创建并启动容器时， Docker 在后台运行的标准 操作包括：

- 检查本地是否存在指定的镜像，不存在就从公有仓库下载；
- 利用镜像创建一个容器，并启动该容器； 
- 分配一个文件系统给容器，并在只读的镜像层外面挂载一层可读写层； 
- 从宿主主机配置的网桥接口中桥接一个虚拟接口到容器中去； 
- 从网桥的地址池配置一个 IP 地址给容器；
-  执行用户指定的应用程序； 
- 执行完毕后容器被自动终止

下面的命令启动一个 bash 终端，允许用户进行交互：

```shell
[root@192 ~]# docker run -it ubuntu:18.04 /bin/bash
root@5847d9abb31f:/#
```

其中，-t 选项让 Docker 分配一个伪终端 (pseudo-tty) 并绑定到容器的标准输入上，－i 则让容器的标准输入保持打开。更多的命令选项可以通过 man docker-run 命令来查看。

在交互模式下，用户可以通过所创建的终端来输入命令，例如：

```shell
root@5847d9abb31f:/# pwd
/
root@5847d9abb31f:/# ls
bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var


root@5847d9abb31f:/# ps
   PID TTY          TIME CMD
     1 pts/0    00:00:00 bash
    12 pts/0    00:00:00 ps
```

在容器内用 ps 命令查看进程，可以看到，只运行了 bash 应用，并没有运行其他无关的进程。

用户可以按 Ctrl+d 或输入 exit 命令来退出容器：

```shell
root@5847d9abb31f:/# exit
exit
```

对于所创建的 bash 容器，当用户使用 exit 命令退出 bash 进程之后，容器也会自动退 出。这是因为对于容器来说，当其中的应用退出后，容器的使命完成，也就没有继续运行的 必要了。

可以使用 docker container wait CONTAINER [CONTAINER.. ．］子命令来等待 容器退出，并打印退出返回结果

某些时候，执行 docker [container]  run 时候因为命令无法正常执行容器会出错 直接退出，此时可以查看退出的错误代码。

默认情况下，常见错误代码包括：

- 125: Docker daemon 执行出错，例如指定了不支持的Docker 命令参数；
- 126: 所指定命令无法执行，例如权限出错；
- 127：容器内命令无法找到。

命令执行后出错，会默认返回命令的退出错误码。

## 4. 守护态运行

更多的时候，需要让 Docker 容器在后台以守护态 (Daemonized) 形式运行。此时，可以 通过添加－d 参数来实现。

 例如，下面的命令会在后台运行容器：

```shell
[root@192 ~]# docker run -d ubuntu /bin/bash -c "while true;do echo hello world; sleep 1;done"
e313b472002228a1a8e55b2c396798d106c3adc685172da97b4351cc49952eb0
```

容器启动后会返回一个唯一的 id, 也可以通过 docker ps 或 docker container ls  命令来查看容器信息：

```shell
[root@192 ~]# docker ps
CONTAINER ID   IMAGE           COMMAND                  CREATED          STATUS          PORTS     NAMES
e313b4720022   ubuntu          "/bin/bash -c 'while…"   24 seconds ago   Up 22 seconds             epic_hertz
```

## 5. 查看容器输出

要获取容器的输出信息，可以通过 docker [container]  logs 命令。

该命令支持的选项包括：

-  -details ：打印详细信息；
-  -f,  -follow: 持续保持输出；
- -since string:  输出从某个时间开始的日志；
- -tails  string:  输出最近的若干日志；
- -t，-timestamps: 显示时间戳信息；
- -until string:  输出某个时间之前的日志。

例如，查看某容器的输出可以使用如下命令：

```shell
[root@192 ~]# docker logs -t e313b4720022
2022-08-16T14:55:50.200216460Z hello world
...
```

