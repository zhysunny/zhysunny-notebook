## 开启jmx参数

-Djava.rmi.server.hostname=127.0.0.1
-Dcom.sun.management.jmxremote.port=1000
-Dcom.sun.management.jmxremote.ssl=false
-Dcom.sun.management.jmxremote.authenticate=false

## 默认jmx信息

### 系统相关指标

* 系统信息收集

java.lang:type=OperatingSystem

* 线程信息收集

java.lang:type=Threading

* 缓存池信息收集

java.nio:type=BufferPool,name=direct

java.nio:type=BufferPool,name=mapped

### GC相关指标(不同的GC处理器不一样，下面是G1)

* Young GC

java.lang:type=GarbageCollector,name=G1 Young Generation

* Old GC

java.lang:type=GarbageCollector,name=G1 Old Generation

### JVM相关指标