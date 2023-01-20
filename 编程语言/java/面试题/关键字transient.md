# 关键字transient

## 初识transient关键字

其实这个关键字的作用很好理解，就是简单的一句话：将不需要序列化的属性前添加关键字transient，序列化对象的时候，这个属性就不会被序列化。

```
public class User implements Serializable {

    private static final long serialVersionUID = 7664394678232470431L;

    private transient String name;
    private static int age;
    private int sex;
    private transient static String desc;

    getter,setter
    toString

}

public class Test {

    private static File file;

    public static void main(String[] args) throws IOException, ClassNotFoundException {
        file = new File("temp.txt");
        User user = new User();
        user.setName("名称");
        User.setDesc("描述");
        User.setAge(22);
        user.setSex(1);
        serialization(user);
        user = deserialization();
        System.out.println(user);
    }

    private static void serialization(User user) throws IOException {
        ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream(file));
        oos.writeObject(user);
        oos.close();
    }

    private static User deserialization() throws IOException, ClassNotFoundException {
        ObjectInputStream ois = new ObjectInputStream(new FileInputStream(file));
        User user = (User)ois.readObject();
        return user;
    }

}

```

打印结果：
```
User{name='null', desc='描述', age='22', sex='1'}
```
由于name被transient修饰，所以没有被序列化

下面测试静态变量

```
public static void main(String[] args) throws IOException, ClassNotFoundException {
    file = new File("temp.txt");
    User user = deserialization();
    System.out.println(user);
}
```
打印结果：
```
User{name='null', desc='描述', age='0', sex='0'}
```
这时不管静态变量有没有被transient修饰，都没有被序列化，原因是静态变量存在方法区

## transient底层实现原理是什么

java的serialization提供了一个非常棒的存储对象状态的机制，说白了serialization就是把对象的状态存储到硬盘上 去，等需要的时候就可以再把它读出来使用。有些时候像银行卡号这些字段是不希望在网络上传输的，transient的作用就是把这个字段的生命周期仅存于调用者的内存中而不会写到磁盘里持久化，意思是transient修饰的age字段，他的生命周期仅仅在内存中，不会被写到磁盘中。

## 被transient关键字修饰过得变量真的不能被序列化嘛

想要解决这个问题，首先还要再重提一下对象的序列化方式：

Java序列化提供两种方式。

一种是实现Serializable接口

另一种是实现Exteranlizable接口。 需要重写writeExternal和readExternal方法，它的效率比Serializable高一些，并且可以决定哪些属性需要序列化（即使是transient修饰的），但是对大量对象，或者重复对象，则效率低。

从上面的这两种序列化方式，我想你已经看到了，使用Exteranlizable接口实现序列化时，我们自己指定那些属性是需要序列化的，即使是transient修饰的。下面就验证一下

```
public class User1 implements Externalizable {

    private static final long serialVersionUID = 7664394678232470431L;

    private transient String name;
    private static int age;
    private int sex;
    private transient static String desc;

    getter,setter
    toString

    @Override
    public void writeExternal(ObjectOutput out) throws IOException {
        out.writeObject(name);
        out.writeInt(age);
        out.writeInt(sex);
        out.writeObject(desc);
    }

    @Override
    public void readExternal(ObjectInput in) throws IOException, ClassNotFoundException {
        name = (String)in.readObject();
        age = in.readInt();
        sex = in.readInt();
        desc = (String)in.readObject();
    }

}

public class Test {

    private static File file;

    public static void main(String[] args) throws IOException, ClassNotFoundException {
        file = new File("temp.txt");
        User1 user = new User1();
        user.setName("名称");
        User1.setDesc("描述");
        User1.setAge(22);
        user.setSex(1);
        serialization(user);
        user = deserialization();
        System.out.println(user);
    }

    private static void serialization(User1 user) throws IOException {
        ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream(file));
        oos.writeObject(user);
        oos.close();
    }

    private static User1 deserialization() throws IOException, ClassNotFoundException {
        ObjectInputStream ois = new ObjectInputStream(new FileInputStream(file));
        User1 user = (User1)ois.readObject();
        return user;
    }

}
```
打印结果：
```
User{name='名称', desc='描述', age='22', sex='1'}
```
结果基本上验证了我们的猜想，也就是说，实现了Externalizable接口，哪一个属性被序列化使我们手动去指定的，即使是transient关键字修饰也不起作用。并且静态变量也可以被序列化

## transient关键字总结

java 的transient关键字为我们提供了便利，你只需要实现Serilizable接口，将不需要序列化的属性前添加关键字transient，序列化对象的时候，这个属性就不会序列化到指定的目的地中。像银行卡、密码等等这些数据。这个需要根据业务情况了。