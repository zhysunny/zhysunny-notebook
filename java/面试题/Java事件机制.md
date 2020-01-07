# Java事件机制

java事件机制包括三个部分：事件、事件监听器、事件源。

## 事件

一般继承自java.util.EventObject类，封装了事件源对象及跟事件相关的信息。 

```
import java.util.EventObject;

/**
 * 事件类,用于封装事件源及一些与事件相关的参数.
 * @author 章云
 * @date 2020/1/6 10:29
 */
public class MyEvent extends EventObject {

    private static final long serialVersionUID = -5209925462736058589L;

    /**
     * Constructs a prototypical MyEvent.
     * @param source 事件源
     * @throws IllegalArgumentException if source is null.
     */
    public MyEvent(Object source) {
        super(source);
    }

}
```

## 事件监听器

实现java.util.EventListener接口,注册在事件源上,当事件源的属性或状态改变时,取得相应的监听器调用其内部的回调方法。 

```
import java.util.EventListener;

/**
 * 事件监听器，实现java.util.EventListener接口。定义回调方法，将你想要做的事放到这个方法下,因为事件源发生相应的事件时会调用这个方法。
 * @author 章云
 * @date 2020/1/6 10:31
 */
public class MyEventListener implements EventListener {

    /**
     * 事件发生后的回调方法
     * @param event
     */
    public void fireMyEvent(MyEvent event) {
        MyEventSource source = (MyEventSource)event.getSource();
        System.out.println("My name has been changed!");
        System.out.println("I got a new name,named \"" + source.getName() + "\"");
    }

}
```

## 事件源

事件发生的地方，由于事件源的某项属性或状态发生了改变(比如BUTTON被单击、TEXTBOX的值发生改变等等)导致某项事件发生。换句话说就是生成了相应的事件对象。因为事件监听器要注册在事件源上,所以事件源类中应该要有盛装监听器的容器(List,Set等等)。 

```
import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;

/**
 * 事件源。事件发生的地方，由于事件源的某项属性或状态发生了改变(比如BUTTON被单击、TEXTBOX的值发生改变等等)导致某项事件发生。换句话说就是生成了相应的事件对象。因为事件监听器要注册在事件源上,所以事件源类中应该要有盛装监听器的容器(List,Set等等)。
 * @author 章云
 * @date 2020/1/6 10:40
 */
public class MyEventSource {

    private String name;
    /**
     * 监听器容器
     */
    private Set listener;

    public MyEventSource() {
        this.listener = new HashSet();
        this.name = "default_name";
    }

    /**
     * 给事件源注册监听器
     * @param listener
     */
    public void addCusListener(MyEventListener listener) {
        this.listener.add(listener);
    }

    /**
     * 当事件发生时,通知注册在该事件源上的所有监听器做出相应的反应（调用回调方法）
     */
    protected void notifies() {
        MyEventListener listener = null;
        Iterator<MyEventListener> iterator = this.listener.iterator();
        while (iterator.hasNext()) {
            listener = iterator.next();
            listener.fireMyEvent(new MyEvent(this));
        }
    }

    public String getName() {
        return name;
    }

    /**
     * 模拟事件触发器，当成员变量name的值发生变化时，触发事件。
     * @param name
     */
    public void setName(String name) {
        if (!this.name.equals(name)) {
            this.name = name;
            notifies();
        }
    }

}
```

## 主方法类 

```
/**
 * 事件机制，观察者模式
 * @author 章云
 * @date 2020/1/6 10:52
 */
public class Main {

    public static void main(String[] args) {
        MyEventSource source = new MyEventSource();
        //注册监听器
        source.addCusListener(new MyEventListener() {
            @Override
            public void fireMyEvent(MyEvent event) {
                super.fireMyEvent(event);
            }
        });
        //触发事件
        source.setName("eric");
    }

}
```
