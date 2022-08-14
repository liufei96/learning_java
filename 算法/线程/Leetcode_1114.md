[1114. 按序打印 - 力扣（LeetCode）](https://leetcode.cn/problems/print-in-order/)

给你一个类：

```java
public class Foo {
  public void first() { print("first"); }
  public void second() { print("second"); }
  public void third() { print("third"); }
}
```


三个不同的线程 A、B、C 将会共用一个 Foo 实例。

- 线程 A 将会调用 first() 方法
- 线程 B 将会调用 second() 方法
- 线程 C 将会调用 third() 方法

请设计修改程序，以确保 second() 方法在 first() 方法之后被执行，third() 方法在 second() 方法之后被执行。

**提示：**

- 尽管输入中的数字似乎暗示了顺序，但是我们并不保证线程在操作系统中的调度顺序。
- 你看到的输入格式主要是为了确保测试的全面性。

**示例 1**：

```shell
输入：nums = [1,2,3]
输出："firstsecondthird"
解释：
有三个线程会被异步启动。输入 [1,2,3] 表示线程 A 将会调用 first() 方法，线程 B 将会调用 second() 方法，线程 C 将会调用 third() 方法。正确的输出是 "firstsecondthird"。
```

**示例 2：**

```shell
输入：nums = [1,3,2]
输出："firstsecondthird"
解释：
输入 [1,3,2] 表示线程 A 将会调用 first() 方法，线程 B 将会调用 third() 方法，线程 C 将会调用 second() 方法。正确的输出是 "firstsecondthird"。
```

**提示：**

- `nums` 是 `[1, 2, 3]` 的一组排列



提取关键信息：

> 1、线程输出要保证顺序
>
> 2、只输出一次

```java
public class Foo {
	// 使用可见的标识符
    private volatile int thread = 1;

    public void first() {
        while (thread != 1) {
        }
        print("first");
        thread = 2;
    }

    public void second() {
        while (thread != 2) {
        }
        print("second");
        thread = 3;
    }

    public void third() {
        while (thread != 3) {
        }
        print("third");
        thread = 1;
    }

    private void print(String msg) {
        System.out.println(msg);
    }

    public static void main(String[] args) {
        Foo foo = new Foo();
        Thread thread1 = new Thread(() -> {
            foo.first();
        });
        Thread thread2 = new Thread(() -> {
            foo.second();
        });
        Thread thread3 = new Thread(() -> {
            foo.third();
        });

        thread1.start();
        thread2.start();
        thread3.start();
    }
}

```