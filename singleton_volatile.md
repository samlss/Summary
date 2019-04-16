#### 单例模式+valatile关键字

##### 下面为单例的几种形式：
```
public static class Singleton{
    private static volatile Singleton sSingleton;

    private Singleton(){
        PLog.e("singleton constructor");
    }

    //饿汉式，线程安全，构造函数带参数的话有限制，且有可能发生
    //没有用到该示例，但是该类已实例化的情况，即有可能还没用到的时候
    //就已经创建了
    private static Singleton sHungrySingleton = new Singleton();

    public static Singleton hungry(){
        return sHungrySingleton;
    }

    //懒汉式，线程安全，性能差
    public static synchronized Singleton lazy(){
        if (sSingleton == null){
            sSingleton = new Singleton();
        }
        return sSingleton;
    }

    //双重检查，线程安全，配合volatile关键字使用，否则还是有可能发生并发问题
    //这里的并发问题不是会导致Singleton初始化两次，实际存在的问题是无序性，
    //在new Singleton()的时候，这个new操作时无序性的，它可能会被编译成
    //- a.先分配内存，让instance指向它(注意这时构造函数还没执行)
    //- b.在内存中创建对象(构造函数执行完毕)
    //synchronized虽然是互斥的，但不代表一次就把整个过程执行完，它在中间是可能释
    //放时间片的，时间片不是锁。释放放时间片的瞬间，
    //另一个线程如果再调用getInstance的话，这时instance不为null，
    //但是还没初始化完成，这时候调用instance的相关属性或者方法的话就会导致
    //空指针异常。因此需要配合volatile来使用。
    
    //这里唯一的区别是加了volatile关键字，那么会有什么现象？ 
    //这时要区分jdk版本了，在jdk1.5之前，volatile并不能保证new操作的有序性，
    //但是它能保证可见性，因此标记1处，读到的不是null，导致了问题。 
    //从1.5开始，加了volatile关键字的引用，它的初始化就不能是： 
    //- a. 先分配内存，让instance指向这块内存 
    //- b. 在内存中创建对象

    //而应该是： 
    //- a.在内存中创建对象 
    //- b.让instance指向这个对象
    
    //其中差距就是保证先创建对象，然后再将instance指向这个对象
    if (sSingleton == null){
            synchronized (Singleton.class){
                if (sSingleton == null){
                    sSingleton = new Singleton();
                }
            }
        }

        return sSingleton;
    }

    //静态内部类单例，线程安全，用到时才创建，构造函数带参数的话有限制
    public static Singleton innerSingleton(){
        return InnerSingleton.sSingleton;
    }

    private static class InnerSingleton{
        private static Singleton sSingleton = new Singleton();
    }
}
```

##### 关于volatile:
在jdk1.5之前，volatile只是保证可见性，即一个线程修改了这个变量的值，其他线程能够立即看得到到修改的值。
在jdk1.5之后，volatile还能够保证有序性。

一旦一个共享变量（类的成员变量、类的静态成员变量）被volatile修饰之后，那么就具备了两层语义：
(1)保证了不同线程对这个变量进行操作时的可见性，即一个线程修改了某个变量的值，这新值对其他线程来说是立即可见的。

(2)禁止进行指令重排序。

关于有序性，在Java内存模型中，允许编译器和处理器对指令进行重排序，但是排序过程不会影响单线程，却会影响多线程并发的正确性。

##### 为什么编译器和处理器会对指令进行重排序？
下面代码分析一下：
```
int a = 100;
byte[] bytes = new byte[1024*1024];
boolean flag = false;
```
这段代码如果cpu不进行重排序的话，会根据书写顺序执行，那么就存在问题，在执行到bytes = new byte[1024*1024]的时候需要去分配内存，因为cpu执行速度比内存分配的速度快，那么这里就需要等待内存分配结束之后才能调用flag = false。所以，为了尽可能减少内存操作速度远慢于CPU运行速度所带来的CPU空置影响，虚拟机会有自己的一些将指令进行重排序的规则，例如这里限制性flag = false，最后再执行bytes = new byte[]，这样可以提升CPU使用效率。
