//
//  Client.h
//  socketServer
//
//  Created by Lu Kejin on 1/25/12.
//  Copyright (c) 2012 Taobao.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Client : NSObject{
    NSOutputStream *outputStream;
    NSInputStream *inputStream;
    
    int sock_fd;
}
@property(nonatomic,retain) NSOutputStream *outputStream;
@property(nonatomic,retain) NSInputStream *inputStream;

@property(nonatomic,assign) int sock_fd;
@end
