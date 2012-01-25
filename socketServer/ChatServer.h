//
//  ChatServer.h
//  socketServer
//
//  Created by Lu Kejin on 1/25/12.
//  Copyright (c) 2012 Taobao.com. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

typedef enum {
    kServerCouldNotBindToIPv4Address = 1,
    kServerCouldNotBindToIPv6Address = 2,
    kServerNoSocketsAvailable = 3,
    kServerNoSpaceOnOutputStream = 4,
    kServerOutputStreamReachedCapacity = 5 // should be able to try again 'later'
} ServerErrorCode;

@interface ChatServer : NSObject<NSStreamDelegate>{
    CFSocketRef _socket;
    uint16_t _port;
    
    NSMutableDictionary *clients;
}
@property(nonatomic,assign) uint16_t port;
@property(nonatomic,retain) NSMutableDictionary *clients;
- (BOOL)run:(NSError **)error;

@end
