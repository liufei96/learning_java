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

# 4.2 停止容器

主要介绍 Docker容器的 p'ause/unpause op prune 子命令。

## 1.暂停容器

docker pause CONTAINER 命令来暂 停一个运行中的容器。

例如，启动一个容器，并将其暂停：

```shell
# -rm=true|false 容器推出后自动删除，不能跟-d 同时使用
[root@192 ~]# docker run --name test -rm -it ubuntu bash
root@670420fa2c34:/#

# 在打开一个终端窗口
[root@192 ~]# docker pause test
test
[root@192 ~]# docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED          STATUS                   PORTS     NAMES
670420fa2c34   ubuntu    "bash"    29 seconds ago   Up 27 seconds (Paused)             test
```

处与 paused 状态的容器，可以使用 docker   unpause CONTAINER  命令来恢复到运行状态。

## 2.终止容器

docker [container]  stop [-t |--time[=10]] [CONTAINER...]

该命令会首先向容器发送 STGTERM 信号，等待一段超时时间后（默认为 10 秒），再发 SIGKILL 信号来终止容器:

```shell
# 默认等待时间是 10s
[root@192 ~]# docker stop test
test

# 加上等待时间
[root@192 ~]# docker stop -t 3 test
test

```

此时，执行 docker container prune 命令，会自动清除掉所有处于停止状态的容器。

```shell
[root@192 ~]# docker container prune
WARNING! This will remove all stopped containers.
Are you sure you want to continue? [y/N] y
Deleted Containers:
670420fa2c345a0bb346caaf1534a48612b925b6ef03993771ee54c2b6b3e424
e313b472002228a1a8e55b2c396798d106c3adc685172da97b4351cc49952eb0
5847d9abb31f887c4447d6fcb41c9ac0f4f704fd12744d8f0e95c9548eb87f24
5bb3349f482bcb0537a83ee35c7ade6faee64956e1b37b038d1f2727a2db2cad
46d226765327ec8742e5d847a0fcfc95b2cfc56fb35f465090031ca8d802af97
54b471bdb24f985043645377328de83ae078ef0d67674771b17799ebb26ef39a
8639d03debf4345a409450b48a2c914a9ab054c06f98c9e09ed5714ca2a07a4c
c45fa8273756df28c4ac53b321843d08789539f15b90bf65f50beb6a341fcfb8
c3c8f3c3007e3b94f6259b8b60ae7aab0a452b0c3091001bec1bac4fda543d16
a3e96c49d66cc31c449d2deefcb01339f6ac990ba2dd2ff97ed88a84b3d03e82

Total reclaimed space: 42.81MB

# 再次通过docker ps -a 所有的容器，发现是空
[root@192 ~]# docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

此外，还可以通过 docker [container] kill 直接发送 SIGKILL 信号来强行终止 容器。

当Docker 容器中指定的应用终结时，容器也会自动终止。例如，对于上一章节中只启 动了一个终端的容器，用户通过 exit 命令或 Ctrl+d 来退出终端时，所创建的容器立刻终 止，处于 stopped 状态。

可以用 docker ps  -qa 命令看到所有容器的 ID 。例如：

```shell
[root@192 ~]# docker ps -qa
973d9795c28d
```

处于终止状态的容器，可以通过 docker [ container] start 命令来重新启动：

```shell
[root@192 ~]# docker start 973d9795c28d
973d9795c28d


[root@192 ~]# docker ps  -a
CONTAINER ID   IMAGE     COMMAND   CREATED         STATUS          PORTS     NAMES
973d9795c28d   ubuntu    "bash"    4 minutes ago   Up 15 seconds             loving_lederberg
```

docker [ container] restart 命令会将一个运行态的容器先终止，然后再重新 启动：

```shell

[root@192 ~]# docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED         STATUS              PORTS     NAMES
973d9795c28d   ubuntu    "bash"    5 minutes ago   Up About a minute             loving_lederberg
[root@192 ~]# docker restart 973d9795c28d
973d9795c28d
[root@192 ~]# docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED         STATUS         PORTS     NAMES
973d9795c28d   ubuntu    "bash"    5 minutes ago   Up 5 seconds             loving_lederberg

```

# 4.3 进入容器

在使用－d 参数时，容器启动后会进入后台，用户无法看到容器中的信息，也无法进行 操作。 

这个时候如果需要进入容器进行操作，推荐使用官方的 attach 或 exit 命令。

## 1. attach命令

attach Docker 自带的命令，命令格式为：

docker [container] attach [--detach-keys [= []]]  [--no-stdin] [--sig-proxy[ ＝true]] CONTAINER

这个命令支持三个主要选项：

-  --detach-keys [=[]]：指定退出 attach 模式的快捷键序列，默认是 CTRL-p CTRL-q;
- \- -no-stdin＝true I false: 是否关闭标准输入，默认是保持打开；
- --sig-proxy＝true I false: 是否代理收到的系统信号给应用进程，默认为 true

下面示例如何使用该命令：

```shell

[root@192 ~]# docker run -itd ubuntu
f774df459e7c2b518ed8e113fe5a821ad16dc1aa568608fdae19e5746df86211

[root@192 ~]# docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED          STATUS         PORTS     NAMES
f774df459e7c   ubuntu    "bash"    7 seconds ago    Up 5 seconds             stupefied_meninsky

[root@192 ~]# docker attach stupefied_meninsky
root@f774df459e7c:/#
```

**然而使用 attach 命令有时候并不方便。当多个窗口同时 attach 到同一个容器的时 候，所有窗口都会同步显示；当某个窗口因命令阻塞时，其他窗口也无法执行操作了。**

## 2.exec 命令

从Docker 1.3.0 版本起， Docker 提供了一个更加方便的工具 exec 命令，可以在运行 中容器内直接执行任意命令。

该命令的基本格式为：

docker [container] exec [-di --detach] [--de ach-keys [= []]] [-i 1--interac ive] [--privileged] ［一t -－tty] [-ul--user [=USER]] CONTAINER COMMAND [ARG... ]

比较重要的参数有：

- -d, --detach ：在容器中后台执行命令；
-  --detach-keys=”“ ：指定将容器切回后台的按键；
- \- e, - - env= []：指定环境变量列表；
- -i, --interactive ＝ true I false: 打开标准输入接受用户输入命令，默认值为 false; 
- --privileged＝true I false: 是否给执行命令以高权限，默认值为 false;
- -t， --tty ＝true I false: 分配伪终端，默认值为 false;
- -u, --user="": 执行命令的用户名或 ID。

例如，进入到刚创建的容器中，并启动一个 bash：

```shell
[root@192 ~]# docker exec -it f774df459e7c /bin/bash
root@f774df459e7c:/#

# 此时要想推出终端
#1. exit 退出终端会导致容器退出
#2. Ctrl + P + Q 仅退出终端
```

可以看到会打开一个新的 bash 终端，在不影响容器内其他应用的前提下，用户可以与 容器进行交互。

> 注意：通过指定－t参数来保持标准输入打开，并且分配一个伪终端。通过 exec 命令对 容器执行操作是最为推荐的方式。

进一步地，可以在容器中查看容器中的用户和进程信息：

```shell

root@f774df459e7c:/# w
 14:47:08 up 55 min,  0 users,  load average: 0.08, 0.03, 0.05
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
root@f774df459e7c:/# ps -ef
UID         PID   PPID  C STIME TTY          TIME CMD
root          1      0  0 14:43 pts/0    00:00:00 bash
root          9      0  0 14:44 pts/1    00:00:00 /bin/bash
root         17      0  0 14:47 pts/2    00:00:00 /bin/bash
root         26     17  0 14:47 pts/2    00:00:00 ps -ef
```

# 4.4 删除容器

可以使用 docker [container] rm 命令来删除处于终止或退出状态的容器，命令格式为 docker [container] rm [-fl--force] [-11--link] [-vl--volumes]CONTAINER  [CONTAINER...]。

主要支持的选项包括：

- -f , --fore=false: 是否强行终止并删除一个运行中的容器；
- -l, --link=false: 删除容器的链接，但保留容器
- -v, --volumes=false: 删除容器挂在的数据卷。

例如，查看处与终止状态的容器，并删除：

```shell
[root@192 ~]# docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED        STATUS                            PORTS     NAMES
973d9795c28d   ubuntu    "bash"    24 hours ago   Exited (137) About a minute ago             loving_lederberg
[root@192 ~]# docker rm 973d9795c28d
973d9795c28d
```

**默认情况下， docker rm 命令只能删除已经处于终止或退出状态的容器，并不能删除 还处千运行状态的容器。**

```shell
[root@192 ~]# docker rm f774df459e7c
Error response from daemon: You cannot remove a running container f774df459e7c2b518ed8e113fe5a821ad16dc1aa568608fdae19e5746df86211. Stop the container before attempting removal or force remove
```

如果要直接删除一个运行中的容器，可以添加－ 参数。 Docker 会先发送 SIGKILL 信号给容器，终止其中的应用，之后强行删除：

```shell
[root@192 ~]# docker rm -f f774df459e7c
f774df459e7c
```

# 4.5 导人和导出容器

某些时候，需要将容器从一个系统迁移到另外一个系统，此时可以使用 Docker 的导入 和导出功能，这也是 Docker 自身提供的一个重要特性。

## 1．导出容器

导出容器是指，导出一个巳经创建的容器到一个文件，**不管此时这个容器是否处于运行 状态**。可以使用 docker [container] export 命令，该命令格式为：

```shell
docker [container] export [-ol--output[=""l CONTAINER
```

其中，可以通过－o 选项来指定导出的 tar 文件名，也可以直接通过重定向来实现。 首先，查看所有的容器，如下所示：

```shell
[root@192 ~]# docker ps -a
CONTAINER ID   IMAGE     COMMAND                  CREATED          STATUS                      PORTS     NAMES
92c12ef9cdda   ubuntu    "bash"                   4 seconds ago    Exited (0) 3 seconds ago              vigorous_bhabha
23e89cb7de5a   ubuntu    "/bin/echo 'Hello wo…"   18 seconds ago   Exited (0) 17 seconds ago             quirky_driscoll
```

分别导出 92c12ef9cdda 容器 和 23e89cb7de5a 容器到 test_for_run.tar 文件和 test_for_stop.tar 文件

```shell

[root@192 ~]# docker export -o test_for_run.tar 92c12ef9cdda
[root@192 ~]# ll
总用量 78500
-rw-r--r--. 1 root root        0 6月  21 23:22 -
-rw-------. 1 root root     1204 6月  21 23:05 anaconda-ks.cfg
drwxr-xr-x. 2 root root       48 8月  14 23:18 dokcer
-rw-r--r--. 1 root root    20009 6月   7 18:08 index.html
-rw-------. 1 root root 80355840 8月  18 22:49 test_for_run.tar


[root@192 ~]# docker export 23e89cb7de5a > test_for_stop.tar
[root@192 ~]# ll
总用量 156976
-rw-r--r--. 1 root root        0 6月  21 23:22 -
-rw-------. 1 root root     1204 6月  21 23:05 anaconda-ks.cfg
drwxr-xr-x. 2 root root       48 8月  14 23:18 dokcer
-rw-r--r--. 1 root root    20009 6月   7 18:08 index.html
-rw-------. 1 root root 80355840 8月  18 22:49 test_for_run.tar
-rw-r--r--. 1 root root 80355840 8月  18 22:50 test_for_stop.tar
```

## 2. 导入容器

使用docker [container] import 命令导入变成镜像，该命令格式为：

```shell
docker import [-c]--change[=[]] [-m]--message[=MESSAGE] file|URL|-[REPOSITORY[:TAG]]
```

用户可以通过－c, --change=[] 选项在导入的同时执行对容器进行修改的 Dockerfile 指令（可参考后续相关章节）。

```shell
[root@192 ~]# docker import test_for_run.tar test/ubuntu:v1.0
sha256:36cf845587aa1acff94825789720ca63875387bb9e63c430bc41dafb1d67dcc7


[root@192 ~]# docker images
REPOSITORY               TAG       IMAGE ID       CREATED         SIZE
test/ubuntu              v1.0      36cf845587aa   8 seconds ago   77.8MB
```

过使用docker load 命令来导入一个镜像 文件，与 docker [container] import命令十分类似。

实际上，既可以使用 docker load 命令来导入镜像存储文件到本地镜像库，也可以使用 docker [container] import命令来导入一个容器快照到本地镜像库。

区别在于：

- 容器快照文件将丢弃所有的历史记录和元数据信息（即仅保存容器当时的快照状态）， 
- 而镜像存储文件将保存完整记录，体积更大。
- 此外，从容器快照文件导入时可以重新指定标 签等元数据信息。

# 4.6 查看容器

主要介绍 Docker 容器的 inspect、top和stats 子命令

## 1.查看容器详情

查看容器详情可以使用 docker container inspect [OPTIONS] CONTAINER  [CONTAINER.. ．]子命令。

例如，查看某容器的具体信息，会以 json 格式返回包括容器 Id 、创建时间、路径、状态、镜像、配置等在内的各项信息：

```shell
[root@192 ~]# docker container inspect 92c12ef9cdda
[
    {
        "Id": "92c12ef9cdda9fdf789cedaf5a10234a403acc69603f063a2267873536cc3f29",
        "Created": "2022-08-18T14:46:50.778727045Z",
        "Path": "bash",
        "Args": [],
        "State": {
            "Status": "exited",
            ...
        },
      ...
    }
]
```

## 2. 查看容器内进程

查看容器内进程可以使用 docker [container] top [OPTTONS]  CONTAINER  [CONTAINER.. ．]子命令。

这个子命令类似于 Linux 系统中的 top 命令，会打印出容器内的进程信息，包括 PID 用户、时间、命令等。例如，查看某容器内的进程信息，命令如下：

```shell

[root@192 ~]# docker top 89c5d2a949cc
UID                 PID                 PPID                C                   STIME               TTY                 TIME                CMD
root                5061                5042                0                   23:15               ?                   00:00:00            /bin/bash -c while true;do echo hello world; sleep 1;done
root                5157                5061                0                   23:15               ?                   00:00:00            sleep 1

```

## 3.查看统计信息

查看统计信息可以使用 docker [container] stats [OPTIONS]  [CONTAINER... ]  子命令，会显示 CPU 、内存、存储、网络等使用情况的统计信息。

支持选项包括：

- -a, -all : 输出所有容器统计信息，默认仅在运行中；
- -format string ：格式化输出信息；
-  -no-stream: 不持续输出，默认会自动更新持续实时结果；
-  -no-trunc:  不截断输出信息。

例如，查看当前运行中容器的系统资源使用统计：

```shell
[root@192 ~]# docker stats 89c5d2a949cc
CONTAINER ID   NAME               CPU %     MEM USAGE / LIMIT   MEM %     NET I/O     BLOCK I/O   PIDS
89c5d2a949cc   interesting_bell   0.19%     460KiB / 7.093GiB   0.01%     656B / 0B   0B / 0B     2
```

# 4.7 其他容器命令

主要介绍 Docker 容器的 cp、diff、port 和 update 子命令。

## 1. 复制文件

container cp 命令支持在容器和主机之间复制文件。命令格式为 docker [container] cp [OPTIONS] CONTAINER:SRC_PATH DEST_PATH _PATHj- 。支持的选项包括：

- -a, -archive：打包模式，复制文件会带有原始的 uid/gid 信息；
- -L，-follow-link：跟随软连接。当原路径为软连接时，默认只复制链接信息， 使用该选项会复制链接的目标内容。

例如，将本地的路径 data 复制到test容器的 /tmp 路径下：

```shell
# 将data目录复制到/tmp目录下
[root@192 ~]# docker cp data/ 89c5d2a949cc:/tmp/
```

## 2. 查看变更

container diff 查看容器内文件系统的变更。命令格式为 docker [container] diff CONTAINER

例如，查看 89c5d2a949cc 容器内的数据修改：

```shell
[root@192 ~]# docker diff 89c5d2a949cc
C /tmp
A /tmp/data
A /tmp/data/test.txt
```

## 3. 查看端口映射

container port 命令可以查看容器的端口映射情况。命令格式为 docker container port CONTAINER· [PRIVATE_PORT [/PROTO]] 。例如，查看 aa511aa1460f  容器的端口映射情况：

```shell
[root@192 ~]# docker port aa511aa1460f
6379/tcp -> 0.0.0.0:6379
6379/tcp -> :::6379
```

## 4. 更新配置

 container update 命令可以更新容器的一些运行时配置，主要是一些资源限制份额。 命令格式为 docker [con tainer] update [OPTIONS] CONTAINER [CONTAINER... ]。

支持的选项包括：

- -blkio-weigh uint6 ：更新块 IO 限制， 10~lOOO ，默认值为0 ，代表着无限制；
- -cpu-period int：限制 CPU 调度器 CFS (Completely Fair Scheduler) 使用时间， 单位为微秒，最小 1000;
- -cpu-quota int：限制 CPU 调度器 CFS 配额，单位为微秒，最小 1000;
- -cpu-rt-period int：限制 CPU 调度器的实时周期，单位为微秒；
-  -cpu-rt-runtime int：限制 CPU 调度器的实时运行时，单位为微秒；
- -c, -cpu-shares int：限制CPU使用份额；
- -cpus decimal：限制CPU 个数
- -cpuset-cpus string：允许使用的CPU核，如 0-3, 0,1; 
- -cpuset-mems string：允许使用的内存块，如 0-3, 0,1;
- -kernel-memory bytes: 限制使用的内核内存；
- -m, -memory bytes ：限制使用的内存；
- -memory-reservation bytes: 内存软限制；
-  -memory-swap bytes ：内存加上缓存区的限制，－l 表示为对缓冲区无限制；
- -restart string: 容器退出后的重启策略。

例如，限制总配额为1 秒，容器迳吐所占用时间为 10% ，代码如下所示：

```shell

[root@192 ~]# docker update --cpu-quota 1000000 89c5d2a949cc
89c5d2a949cc

[root@192 ~]# docker update --cpu-period 100000 89c5d2a949cc
89c5d2a949cc
```

