# TCP协议

1) TCP（Transmission Control Protocol）传输控制协议

TCP是主机对主机层传输控制协议，为提供可靠的连接服务，采用三次握手来确认建立一个连接。采用四次挥手来进行协议的终止。

2) 位码

TCP标志位，有以下6种标示：

|标志位|英文|含义|
|---|---|---|
|SYN|synchronouse|建立连接|
|ACK|acknowledgement|确认标志|
|PSH|push|传送标志|
|FIN|finish|结束标志|
|RST|reset|重置标志|
|URG|urgent|紧急标志|

3) Sequence number 顺序号码

4) Acknowledgement 确认号码

5) 连接状态

|状态|介绍|
|---|---|
|LISTENING|提供某种服务，侦听远方TCP端口的连接请求，当提供的服务没有被连接时，处于LISTENING状态，端口是开放的，等待被连接。|
|SYN_SENT (客户端状态)|客户端调用connect，发送一个SYN请求建立一个连接，在发送连接请求后等待匹配的连接请求，此时状态为SYN_SENT。|
|SYN_RCVD (服务端状态)|在收到和发送一个连接请求后，等待对方对连接请求的确认，当服务器收到客户端发送的同步信号时，将标志位ACK和SYN置1发送给客户端，此时服务器端处于SYN_RCVD状态，如果连接成功了就变为ESTABLISHED，正常情况下SYN_RCVD状态非常短暂。|
|ESTABLISHED|ESTABLISHED状态是表示两台机器正在传输数据。|
|FIN-WAIT-1|等待TCP连接中断请求的确认，主动关闭端应用程序调用close，TCP发出FIN请求主动关闭连接，之后进入FIN_WAIT1状态。|
|FIN-WAIT-2|1、主动关闭端接到FIN ack后，便进入FIN-WAIT-2，这是在关闭连接时，客户端和服务器两次挥手之后的半关闭状态，在这个状态下，客户端应用程序还有接受数据的能力，但是已经无法发送数据；2、另一种情况是主动关闭端收到了服务端的FIN请求|
|CLOSE-WAIT|等待从本地用户发来的连接中断请求 ，被动关闭端TCP接到FIN后，就发出ACK以回应FIN请求(它的接收也作为文件结束符传递给上层应用程序),并进入CLOSE_WAIT|
|CLOSING|等待远程TCP对连接中断的确认,处于此种状态比较少见|
|LAST-ACK|等待原来的发向远程TCP的连接中断请求的确认,被动关闭端一段时间后，接收到文件结束符的应用程序将调用CLOSE关闭连接,TCP也发送一个 FIN,等待对方的ACK.进入LAST-ACK。|
|TIME-WAIT|在主动关闭端接收到FIN后，TCP就发送ACK包，并进入TIME-WAIT状态,等待足够的时间以确保远程TCP接收到连接中断请求的确认,很大程度上保证了双方都可以正常结束。|
|CLOSED|被动关闭端在接受到ACK包后，就进入了closed的状态，连接结束，没有任何连接状态。|

2、三次握手解释

三次握手的图解如上图，每一条箭头代表着一次握手，那么具体是什么意思呢？

第一次握手： Client端发送位码为SYN=1,随机产生seq number=J的数据包到服务器，Server端收到数据包后，由SYN=1判断出 Client端要求连接；此时Client端处于SYN_SENT的状态。

第二次握手： Server端收到请求后要向Client端发送确认连接的信息，于是，Server端向Client端发送一个ACK=1,SYN=1,ack number=J+1(即Client端的seq number +1),随机生成的seq number=K，此时服务端处于SYN_RCVD；

第三次握手：Client端收到后检查两点 ：
* 1、ack number 是否正确（是否等于J+1）；
* 2、位码ACK是否等于1。

若以上两点都正确，Client端会再次发送ack num=K+1(第二次机握手中 Server端发送的seq number + 1)，位码ACK=1，Server端收到后确认ack number值是否正确，ACK是否为1 ，若均正确则连接建立成功。此时双方处于ESTABLISHED的状态。

3、四次挥手

四次挥手的示意图如上图，每一条箭头代表着一次挥手。

第一次挥手： Client端发送位码为FIN=1,随机产生seq number=J的数据包到服务器，Server端收到数据包后，由FIN=1判断出 Client端要求断开连接；此时Client端处于FIN-WAIT-1的状态。

第二次挥手： Server端收到请求后要向Client端发送确认断开连接的信息，于是，Server端向Client端发送一个ACK=1,ack number=J+1(即Client端的seq number +1)，此时服务端处于CLOSE_WAIT的状态，Client端收到这个信号后，由FIN-WAIT-1变成FIN-WAIT-2的状态，此时Client端可以接受Server端的数据但是不能向Server端传输数据。

第三次挥手： Server端主动向Client端发送一个位码为FIN=1,随机产生seq number=K 的数据包到服务器，Client端收到数据包后，由FIN=1判断出Server端要断开连接，此时Server端处于LAST-ACK的状态。

第四次挥手： Client端接受到Server端的请求后，要向Server端发送确认端口连接的信息，于是，Client端向Server端发送了一个ACK=1，ack num=K+1(即Server端的seq number +1)，发送后Client端处于TIME-WAIT的状态，等待2MSL后变成CLOSED，而Server端收到Client端的最后一个ACK后便会变成CLOSED