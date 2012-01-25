//
//  ChatServer.m
//  socketServer
//
//  Created by Lu Kejin on 1/25/12.
//  Copyright (c) 2012 Taobao.com. All rights reserved.
//

#import "ChatServer.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

#import "Client.h"

#define CHAT_SERVER_PORT 11332

NSString * const ServerErrorDomain = @"ChatServerErrorDomain";
static void SocketConnectionAcceptedCallBack(CFSocketRef socket, 
                                             CFSocketCallBackType type, 
                                             CFDataRef address, 
                                             const void *data, void *info);
//用于标准输入
static void FileDescriptorCallBack(CFFileDescriptorRef f,
                                   CFOptionFlags callBackTypes,
                                   void *info);

@implementation ChatServer
@synthesize port = _port;
@synthesize clients;
- (id)init{
    if (self = [super init]) {
        clients = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc{
    if (_socket) {
        CFRelease(_socket);
    }
    [clients release];
    [super dealloc];
}

- (BOOL)run:(NSError **)error{
    BOOL successful = YES;
    CFSocketContext socketCtxt = {0, self, NULL, NULL, NULL};
    _socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, 
                             IPPROTO_TCP, 
                             kCFSocketAcceptCallBack,
                             (CFSocketCallBack)&SocketConnectionAcceptedCallBack,
                             &socketCtxt);
    
	
    if (NULL == _socket) {
        if (nil != error) {
            *error = [[NSError alloc] 
                      initWithDomain:ServerErrorDomain
                      code:kServerNoSocketsAvailable
                      userInfo:nil];
        }
        successful = NO;
    }
	
    if(YES == successful) {
        // enable address reuse
        int yes = 1;
        setsockopt(CFSocketGetNative(_socket), 
                   SOL_SOCKET, SO_REUSEADDR,
                   (void *)&yes, sizeof(yes));
        // set the packet size for send and receive
        // cuts down on latency and such when sending
        // small packets
        uint8_t packetSize = 128;
        setsockopt(CFSocketGetNative(_socket),
                   SOL_SOCKET, SO_SNDBUF,
                   (void *)&packetSize, sizeof(packetSize));
        setsockopt(CFSocketGetNative(_socket),
                   SOL_SOCKET, SO_RCVBUF,
                   (void *)&packetSize, sizeof(packetSize));
        
        // set up the IPv4 endpoint; use port 0, so the kernel 
        // will choose an arbitrary port for us, which will be 
        // advertised through Bonjour
        struct sockaddr_in addr4;
        memset(&addr4, 0, sizeof(addr4));
        addr4.sin_len = sizeof(addr4);
        addr4.sin_family = AF_INET;
        addr4.sin_port = htons(CHAT_SERVER_PORT); 
        addr4.sin_addr.s_addr = htonl(INADDR_ANY);
        NSData *address4 = [NSData dataWithBytes:&addr4 length:sizeof(addr4)];
        
        if (kCFSocketSuccess != CFSocketSetAddress(_socket, (CFDataRef)address4)) {
            if (error) *error = [[NSError alloc] 
                                 initWithDomain:ServerErrorDomain
                                 code:kServerCouldNotBindToIPv4Address
                                 userInfo:nil];
            if (_socket) CFRelease(_socket);
            _socket = NULL;
            successful = NO;
        } else {
            // now that the binding was successful, we get the port number 
            NSData *addr = [(NSData *)CFSocketCopyAddress(_socket) autorelease];
            memcpy(&addr4, [addr bytes], [addr length]);
            self.port = ntohs(addr4.sin_port);
            
            // set up the run loop sources for the sockets
            CFRunLoopRef cfrl = CFRunLoopGetCurrent();
            CFRunLoopSourceRef source4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);
            CFRunLoopAddSource(cfrl, source4, kCFRunLoopDefaultMode);
            CFRelease(source4);
            
            //标准输入，当在命令行中输入时，回调函数便会被调用
            CFFileDescriptorContext context = {0,self,NULL,NULL,NULL};
            CFFileDescriptorRef stdinFDRef = CFFileDescriptorCreate(kCFAllocatorDefault, STDIN_FILENO, true, FileDescriptorCallBack, &context);
            CFFileDescriptorEnableCallBacks(stdinFDRef,kCFFileDescriptorReadCallBack);
            CFRunLoopSourceRef stdinSource = CFFileDescriptorCreateRunLoopSource(kCFAllocatorDefault, stdinFDRef, 0);
            CFRunLoopAddSource(cfrl, stdinSource, kCFRunLoopDefaultMode);
            CFRelease(stdinSource);
            CFRelease(stdinFDRef);
            
            CFRunLoopRun();
        }
	}
    
    return successful;
}

#pragma mark -
#pragma mark NSStream Delegate
- (void) stream:(NSStream*)stream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            break;
        }
        case NSStreamEventHasBytesAvailable: {
            Client *client = [self.clients objectForKey:[NSString stringWithFormat:@"%d",stream]];
            
            NSMutableData *data = [NSMutableData data];
            uint8_t *buf = calloc(128, sizeof(uint8_t));
            NSUInteger len = 0;
            while([(NSInputStream*)stream hasBytesAvailable]) {
                len = [(NSInputStream*)stream read:buf maxLength:128];
                if(len > 0) {
                    [data appendBytes:buf length:len];
                }
            }
            free(buf);
            
            if ([data length] == 0) {
                //客户端退出
                NSLog(@"客户端(sock_fd=%d)退出",client.sock_fd);
                [self.clients removeObjectForKey:[NSString stringWithFormat:@"%d",stream]];
            }else{
                NSLog(@"收到客户端(sock_fd=%d)消息:%@",client.sock_fd,[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
            }
            break;
        }
        case NSStreamEventHasSpaceAvailable: {
            break;
        }
        case NSStreamEventEndEncountered: {
            break;
        }
        case NSStreamEventErrorOccurred: {
            break;
        }
        default:
            break;
    }
}


#pragma mark -
#pragma mark callbacks

static void SocketConnectionAcceptedCallBack(CFSocketRef socket, 
                                             CFSocketCallBackType type, 
                                             CFDataRef address, 
                                             const void *data, void *info) {
    ChatServer *theChatServer = (ChatServer *)info;
    // the server's socket has accepted a connection request
    // this function is called because it was registered in the
    // socket create method
    if (kCFSocketAcceptCallBack == type) { 
        
        // 摘自kCFSocketAcceptCallBack的文档，New connections will be automatically accepted and the callback is called with the data argument being a pointer to a CFSocketNativeHandle of the child socket. This callback is usable only with listening sockets.
        
        CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle *)data;
        // create the read and write streams for the connection to the other process
        CFReadStreamRef readStream = NULL;
		CFWriteStreamRef writeStream = NULL;
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle,
                                     &readStream, &writeStream);
        if(NULL != readStream && NULL != writeStream) {
            CFReadStreamSetProperty(readStream, 
                                    kCFStreamPropertyShouldCloseNativeSocket,
                                    kCFBooleanTrue);
            CFWriteStreamSetProperty(writeStream, 
                                     kCFStreamPropertyShouldCloseNativeSocket,
                                     kCFBooleanTrue);
            
            NSInputStream *inputStream = (NSInputStream *)readStream;
            NSOutputStream *outputStream = (NSOutputStream *)writeStream;
            inputStream.delegate = theChatServer;
            [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [inputStream open];
            outputStream.delegate = theChatServer;
            [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [outputStream open];
            
            Client *aClient = [[Client alloc] init];
            aClient.inputStream = inputStream;
            aClient.outputStream = outputStream;
            aClient.sock_fd = nativeSocketHandle;
            
            [theChatServer.clients setValue:aClient  
                                     forKey:[NSString stringWithFormat:@"%d",inputStream]];
            
            NSLog(@"有新客户端(sock_fd=%d)加入",nativeSocketHandle);
            
        } else {
            // on any failure, need to destroy the CFSocketNativeHandle 
            // since we are not going to use it any more
            close(nativeSocketHandle);
        }
        if (readStream) CFRelease(readStream);
        if (writeStream) CFRelease(writeStream);
    }

}

static void FileDescriptorCallBack(CFFileDescriptorRef f,
                                   CFOptionFlags callBackTypes,
                                   void *info){
    int fd = CFFileDescriptorGetNativeDescriptor(f);
    ChatServer *theChatServer = (ChatServer *)info;
    if (fd == STDIN_FILENO) {
        NSData *inputData = [[NSFileHandle fileHandleWithStandardInput] availableData];
        
        NSString *inputString = [[[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding] autorelease];
        NSLog(@"准备发送消息:%@",inputString);
        
        for (Client *client in [theChatServer.clients allValues]) {
            [client.outputStream write:[inputData bytes] maxLength:[inputData length]];
        }
        //处理完数据之后必须重新Enable 回调函数
        CFFileDescriptorEnableCallBacks(f,kCFFileDescriptorReadCallBack);
    }
}
@end
