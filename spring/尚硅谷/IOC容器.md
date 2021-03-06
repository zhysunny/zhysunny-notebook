## 为什么要使用IOC

假设A和B对象，A需要调用B对象的方法
* 传统模式，在A中new一个B对象，再调用B对象的方法
    缺点：当B改动时，A也需要改动，耦合度高
* 工厂模式：A通过工厂模式获取B对象，A和B之间解耦
    缺点：B对象与工厂存在耦合，每出现一个对象都需要相应的工厂
* xml配置文件：通过发射的方式加载对象，解决代码的频繁改动

创建对象的接口
* BeanFactory：懒加载，最顶端的工厂接口
* ApplicationContext：饿汉式，适合开发人员使用