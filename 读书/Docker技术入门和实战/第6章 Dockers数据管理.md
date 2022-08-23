在生产环境中使用 Docker, 往往需要对数据进行持久化，或者需要在多个容器之间进行 数据共享，这必然涉及容器的数据管理操作。

容器中的管理数据主要有两种方式：

- 数据卷 (Data Volumes) ：容器内数据直接映射到本地主机环境；
- 数据卷容器 (Data Volume Containers)：使用特定容器维护数据卷。

# 6.1 数据卷

数据卷 (Data Volumes) 是一个可供容器使用的特殊目录，它将主机操作系统目录直接 映射进容器，类似于 Linux 中的 mount行为。

数据卷可以提供很多有用的特性：

- 数据卷可以在容器之间共享和重用，容器间传递数据将变得高效与方便；
- 对数据卷内数据的修改会立马生效，无论是容器内操作还是本地操作；
- 对数据卷的更新不会影响镜像，解耦开应用和数据；
- 卷会一直存在，直到没有容器使用，可以安全地卸载它。

## 1. 创建数据卷

Docker 提供了 volume 子命令来管理数据卷，如下命令可以快速在本地创建一个数据卷：

```shell
[root@192 ~]# docker volume create -d local 89c5d2a949cc
89c5d2a949cc
```

此时，查看/var/lib/docker/volumes 路径下，会发现所创建的数据卷位置∶

```shell
[root@192 ~]# ls -l /var/lib/docker/volumes/
总用量 28
drwx-----x. 3 root root     19 7月   3 16:53 03701d369e48a8f4025bd633edb5516939b1053a6c3d2676eaa6c9a85ad7d527
drwx-----x. 3 root root     19 7月   3 16:53 0b8f9b5263dfb719769d5bd65e09fe4adf521a92c1aad2cff73b70fd676b77c9
drwx-----x. 3 root root     19 8月  20 15:49 28d579d15e6b1670d00aaea0a9f56758ff64176e5af51fc7504fc966d4981d2b
drwx-----x. 3 root root     19 8月  20 21:36 89c5d2a949cc
drwx-----x. 3 root root     19 7月   3 16:53 a33587d8ccecf43a1338c28952d900260634637995bc8d9e43059607cfeb7853
drwx-----x. 3 root root     19 7月   2 08:49 b19ceaa9be0a733addcdc42dc53cab19d3a6bf3a0f9f8e7365a5e520dacec1f2
brw-------. 1 root root 253, 0 8月  20 16:34 backingFsBlockDev
-rw-------. 1 root root  32768 8月  20 21:36 metadata.db
```

除了 create 子命令外， docker volume 还支持 inspect（查看详细信息）、 ls（列 出已有数据卷）、 prune （清理无用数据卷）、 rm （删除数据卷）等，读者可以自行实践。

```shell
[root@192 ~]# docker volume inspect 89c5d2a949cc
[
    {
        "CreatedAt": "2022-08-20T21:36:54+08:00",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/89c5d2a949cc/_data",
        "Name": "89c5d2a949cc",
        "Options": {},
        "Scope": "local"
    }
]
```

```shell
[root@192 ~]# docker volume ls
DRIVER    VOLUME NAME
local     0b8f9b5263dfb719769d5bd65e09fe4adf521a92c1aad2cff73b70fd676b77c9
local     28d579d15e6b1670d00aaea0a9f56758ff64176e5af51fc7504fc966d4981d2b
local     89c5d2a949cc
local     03701d369e48a8f4025bd633edb5516939b1053a6c3d2676eaa6c9a85ad7d527
local     a33587d8ccecf43a1338c28952d900260634637995bc8d9e43059607cfeb7853
local     b19ceaa9be0a733addcdc42dc53cab19d3a6bf3a0f9f8e7365a5e520dacec1f2
```

## 2. 绑定数据卷

除了使用 volume 子命令来管理数据卷外，还可以在创建容器时将主机本地的任意路径 挂载到容器内作为数据卷，这种形式创建的数据卷称为绑定数据卷。

在用 docker [container] run 命令的时候，可以使用－mount 选项来使用数据卷。

- volume ：普通数据卷，映射到主机／var/lib/docker/volumes 路径下；
- bind: 绑定数据卷，映射到主机指定路径下；
- tmpfs：临时数据卷，只存在于内存中。

下面使用training/webapp 镜像创建一个 Web 容器，并创建一个数据卷挂载到容器的/opt/webapp 目录：

```shell
[root@192 ~]# docker run -itd -p 6322:22 --name os1 --privileged=true --mount type=bind,source=/root/webapp,destination=/tmp ansible/centos7-ansible
b870bf0661682747c92e881be442751128ce9289f3fc573dee8b7a18c7133630
```

source对应的本地目录需要存在

```shell
[root@192 ~]# docker ps -a
CONTAINER ID   IMAGE                     COMMAND                  CREATED          STATUS                    PORTS                                       NAMES
b870bf066168   ansible/centos7-ansible   "/bin/bash"              53 seconds ago   Up 51 seconds             0.0.0.0:6322->22/tcp, :::6322->22/tcp       os1
```

我们现在本地目录/root/webapp 目录下创建一个文件test.txt

```shell
[root@192 webapp]# ll -ls /root/webapp/
总用量 4
4 -rw-r--r--. 1 root root 5 8月  20 22:02 test.txt
```

```shell
# 进入容器内，发现tmp目录也有一个相同的文件，且文件内容一致
[root@192 ~]# docker exec -it os1 ls /tmp
test.txt
```

上述命令等同于使用旧的-v标记可以在容器内创建一个数据卷∶

```shell
[root@192 webapp]# docker run -itd -p 6323:22 --name os2 --privileged=true -v /root/webapp:/tmp ansible/centos7-ansible
ae35c3063363701eb3555d381dd761f53ed0b75d2a758a7fe825483e926b40b9


[root@192 webapp]# docker exec -it os2 ls -l /tmp
total 4
-rw-r--r--. 1 root root 5 Aug 20 14:02 test.txt
```

这个功能在进行应用测试的时候十分方便，比如用户可以放置一些程序或数据到本地目 录中实时进行更新，然后在容器内运行和使用。 

**另外，本地目录的路径必须是绝对路径，容器内路径可以为相对路径。如果目录不存在， Docker 会自动创建。**

Docker 挂载数据卷的默认权限是读写 (rw) ，用户也可以通过 ro 指定为只读：

```shell
[root@192 webapp]# docker run -itd -p 6324:22 --name os3 --privileged=true -v /root/webapp:/tmp:ro ansible/centos7-ansible
04dbc97ea07e4c570c61502ebef92f1a97a1e6e43c2b86e151d9fda690ab600a


[root@192 webapp]# docker exec -it os3 /bin/bash
[root@04dbc97ea07e ansible]#
[root@04dbc97ea07e ansible]# cd /tmp/
[root@04dbc97ea07e tmp]# ll
total 4
-rw-r--r--. 1 root root 5 Aug 20 14:02 test.txt
[root@04dbc97ea07e tmp]# touch test.txt
touch: cannot touch 'test.txt': Read-only file system

# 在容器外可以

[root@192 webapp]# cat /root/webapp/test.txt
aaaa
[root@192 webapp]# echo 'bbb' > /root/webapp/test.txt
[root@192 webapp]# cat /root/webapp/test.txt
bbb

[root@192 webapp]# docker exec -it os3 cat /tmp/test.txt
bbb
```

加了 :ro 之后，容器内对所挂载数据卷内的数据就无法修改了。 如果直接挂载一个文件到容器，使用文件编辑工具，包括 vi 或者 sed - -in-place  的时候，**可能会造成文件 inode 的改变。从 Docker 1.1.0 起，这会导致报错误信息。所以推荐的方式是直接挂载文件所在的目录到容器内。**

# 6.2 数据卷容器

**如果用户需要在多个容器之间共享一些持续更新的数据，最简单的方式是使用数据卷容 Docker 数据管理令 61 器。数据卷容器也是一个容器，但是它的目的是专门提供数据卷给其他容器挂载。**

首先，创建一个数据卷容器 dbdata, 并在其中创建一个数据卷挂载到/dbdata:

```shell
[root@192 ~]# docker run -it -v /dbdata --name dbdata ubuntu
root@d08771108472:/# ls
bin  boot  dbdata  dev  etc  home  lib  lib32  lib64  libx32  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
```

然后，可以在其他容器中使用--volumes:from 来挂载 dbdata 容器中的数据卷，例如创建 dbl 和 db2 两个容器，并从 dbdata 容器挂载数据卷：

```shell
[root@192 ~]# docker run -it --volumes-from dbdata --name db1 ubuntu

[root@192 ~]# docker run -it --volumes-from dbdata --name db2 ubuntu
```

此时，容器 dbl 和 db2 都挂载同一个数据卷到相同的／dbdata 目录，三个容器任何 一方在该目录下的写入，其他容器都可以看到。

例如，在 dbdata 容器中创建一个 test 文件：

```shell
[root@192 ~]# docker exec -it dbdata /bin/bash
root@d08771108472:/# cd dbdata/

root@d08771108472:/dbdata# touch test
root@d08771108472:/dbdata# ls
test
```

查看db1容器 和 db2容器中

```shell
[root@192 ~]# docker exec -it db1 ls -l /dbdata
total 0
-rw-r--r--. 1 root root 0 Aug 21 07:40 test


[root@192 ~]# docker exec -it db2 ls -l /dbdata
total 0
-rw-r--r--. 1 root root 0 Aug 21 07:40 test
```

可以多次使用 --volumes-from 参数来从多个容器挂载多个数据卷，还可以从其他已 经挂载了容器卷的容器来挂载数据卷：

```shell
[root@192 ~]# docker run -itd --name db3 --volumes-from db1 ubuntu
c70ca733011a9d729252b32266b109086c7ac5991d486b82d0037000f17c5ea9


[root@192 ~]# docker exec -it db3 ls -l /dbdata
total 0
-rw-r--r--. 1 root root 0 Aug 21 07:40 test
```

**注意：使用 --volumes-from 参数所挂载的数据卷的容器自身并不需要保持在运行状态。**

如果删除了挂载的容器（包括 dbda 、dbl 和 db2) ，数据卷并不会被自动删除。如果 要删除一个数据卷，必须在删除最后一个还挂载着它的容器时显式使用 docker rm -v 命令来指定同时删除关联的容器。

使用数据卷容器可以让用户在容器之间自由地升级和移动数据卷，具体的操作将在下一 节进行讲解。

# 6.3 利用数据卷容器来迁移数据

可以利用数据卷容器对其中的数据卷进行备份、恢复，以实现数据的迁移。

## 1.备份

使用下面的命令来备份 dbdata 数据卷容器内的数据卷：

```shell
[root@192 dokcer]# docker run --volumes-from dbdata -v $(pwd):/backup --name worker ubuntu tar cvf /backup/backup.tar /dbdata
tar: Removing leading `/' from member names
/dbdata/
/dbdata/test
```

这个命令稍微有点复杂，具体分析下。

首先利用 ubuntu 镜像创建了一个容器 worker 。使用 -- volumes-from dbdata 参数 来让 worker 容器挂载 dbdata 容器的数据卷（即 dbdata 数据卷；使用 -v $(pwd):/backup  参数来挂载本地的当前目录到 worker 容器的 /backup 目录。

worker 容器启动后，使用 tar cvf /backup/backup.tar  /dbdata 命令将 /dbdata 下内容备份为容器内的／backup/backup.tar, 即宿主主机当前目录下的 backup.tar

## 2.恢复

如果要恢复数据到一个容器，可以按照下面的操作。 首先创建一个带有数据卷的容器 dbdata2:

```shell
[root@192 dokcer]# docker run -v /dbdata --name dbdata2 ubuntu /bin/bash
```

然后创建另一个新的容器，挂载 dbdata2 的容器，并使用 untar 解压备份文件到所挂载的容器卷中：

```shell
[root@192 dokcer]# docker run --volumes-from dbdata2 -v $(pwd):/backup mybuntu tar xvf /backup/backup.tar
dbdata/
dbdata/test
```

在生产环境中，笔者推荐在使用数据卷或数据卷容器之外，定期将主机的本地数据进 行备份，或者使用支持容错的存储系统，包括 RAID 或分布式文件系统，如 Ceph、GPFS、HDFS 等。 

另外，有些时候不希望将数据保存在宿主机或容器中，还可以使用tmpfs 类型的数据卷，其中数据只存在于内存中，容器退出后自动删除。
