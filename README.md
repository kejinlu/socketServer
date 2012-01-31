###点对点聊天服务器端

---
详细文档: [Socket编程][link-socket], 服务器端需要配合客户端进行一次运行，客户端代码在这里:<https://github.com/kejinlu/socketClient>

[link-socket]:https://github.com/kejinlu/objc-doc/blob/master/Socket%E7%BC%96%E7%A8%8B.md

* 1.直接socket接口  `normal分支`
* 2.使用select系统调用  `select分支`
* 3.使用kqueue (很像Linux中的epoll)  `kqueue分支`
* 4.使用Cocoa中的流 `NSStream分支`