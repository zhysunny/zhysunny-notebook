# JVM永久代和元空间

## 永久代

Java 的内存中有一块称之为方法区的部分，在 JDK8 之前， Hotspot 虚拟机中的实现方式为永久代（Permanent Generation），别的JVM都没有这个东西。

在过去（当自定义类加载器使用不普遍的时候），类几乎是“静态的”并且很少被卸载和回收，因此类也可以被看成“永久的”。另外由于类作为 JVM 实现的一部分，它们不由程序来创建，因为它们也被认为是“非堆”的内存。

永久代是一段连续的内存空间，我们在 JVM 启动之前可以通过设置-XX:MaxPermSize的值来控制永久代的大小，32 位机器默认的永久代的大小为 64M，64 位的机器则为 85M。

永久代的垃圾回收和老年代的垃圾回收是绑定的，一旦其中一个区域被占满，这两个区都要进行垃圾回收。但是有一个明显的问题，由于我们可以通过‑XX:MaxPermSize设置永久代的大小，一旦类的元数据超过了设定的大小，程序就会耗尽内存，并出现内存溢出错误 ( java.lang.OutOfMemoryError: PermGen space)。
为什么类的元数据占用内存会那么大？因为在 JDK7 之前的 HotSpot 虚拟机中，纳入字符串常量池的字符串被存储在永久代中，因此导致了一系列的性能问题和内存溢出错误。

为了解决这些性能问题，也为了能够让 Hotspot 能和其他的虚拟机一样管理，元空间就产生了。

## 元空间

元空间是 Hotspot 在 JDK8 中新加的内容，其本质和永久代类似，都是对 JVM 规范中方法区的实现。不过元空间与永久代之间最大的区别在于：

```
元空间并不在虚拟机中，而是使用本地内存。因此，默认情况下，元空间的大小仅受本地内存限制，但可以通过以下参数来指定元空间的大小：

-XX:MetaspaceSize　

初始空间大小，达到该值就会触发垃圾收集进行类型卸载，同时GC会对该值进行调整：如果释放了大量的空间，就适当降低该值；如果释放了很少的空间，那么在不超过MaxMetaspaceSize时，适当提高该值。
　　
-XX:MaxMetaspaceSize
最大空间，默认是没有限制的。

除了上面两个指定大小的选项以外，还有两个与 GC 相关的属性：

-XX:MinMetaspaceFreeRatio

在GC之后，最小的Metaspace剩余空间容量的百分比，减少为分配空间所导致的垃圾收集

-XX:MaxMetaspaceFreeRatio

在GC之后，最大的Metaspace剩余空间容量的百分比，减少为释放空间所导致的垃圾收集
```

## 移除永久代的影响

由于类的元数据分配在本地内存中，元空间的最大可分配空间就是系统可用内存空间。因此，我们就不会遇到永久代存在时的内存溢出错误，也不会出现泄漏的数据移到交换区这样的事情。最终用户可以为元空间设置一个可用空间最大值，如果不进行设置，JVM 会自动根据类的元数据大小动态增加元空间的容量。

注意：永久代的移除并不代表自定义的类加载器泄露问题就解决了。因此，你还必须监控你的内存消耗情况，因为一旦发生泄漏，会占用你的大量本地内存，并且还可能导致交换区交换更加糟糕。

## 元空间内存管理

元空间的内存管理由元空间虚拟机来完成。

先前，对于类的元数据我们需要不同的垃圾回收器进行处理，现在只需要执行元空间虚拟机的 C++ 代码即可完成。在元空间中，类和其元数据的生命周期和其对应的类加载器是相同的。话句话说，只要类加载器存活，其加载的类的元数据也是存活的，因而不会被回收掉。

准确的来说，每一个类加载器的存储区域都称作一个元空间，所有的元空间合在一起就是我们一直说的元空间。当一个类加载器被垃圾回收器标记为不再存活，其对应的元空间会被回收。在元空间的回收过程中没有重定位和压缩等操作。但是元空间内的元数据会进行扫描来确定 Java 引用。

那具体是如何管理的呢？

元空间虚拟机负责元空间的分配，其采用的形式为组块分配。组块的大小因类加载器的类型而异。在元空间虚拟机中存在一个全局的空闲组块列表。

当一个类加载器需要组块时，它就会从这个全局的组块列表中获取并维持一个自己的组块列表。
当一个类加载器不再存活时，那么其持有的组块将会被释放，并返回给全局组块列表。
类加载器持有的组块又会被分成多个块，每一个块存储一个单元的元信息。组块中的块是线性分配（指针碰撞分配形式）。组块分配自内存映射区域。这些全局的虚拟内存映射区域以链表形式连接，一旦某个虚拟内存映射区域清空，这部分内存就会返回给操作系统。

## 运行时常量池

运行时常量池在 JDK6 及之前版本的 JVM 中是方法区的一部分，而在 HotSpot 虚拟机中方法区的实现是永久代(Permanent Generation)。所以运行时常量池也是在永久代的。

但是 JDK7 及之后版本的 JVM 已经将字符串常量池从方法区中移了出来，在堆（Heap）中开辟了一块区域存放运行时常量池。

String.intern()是一个 Native 方法，它的作用是：如果运行时常量池中已经包含一个等于此 String 对象内容的字符串，则返回常量池中该字符串的引用；如果没有，则在常量池中创建与此 String 内容相同的字符串，并返回常量池中创建的字符串的引用。

## 存在的问题

前面已经提到，元空间虚拟机采用了组块分配的形式，同时区块的大小由类加载器类型决定。类信息并不是固定大小，因此有可能分配的空闲区块和类需要的区块大小不同，这种情况下可能导致碎片存在。元空间虚拟机目前并不支持压缩操作，所以碎片化是目前最大的问题。