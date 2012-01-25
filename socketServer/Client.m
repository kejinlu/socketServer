//
//  Client.m
//  socketServer
//
//  Created by Lu Kejin on 1/25/12.
//  Copyright (c) 2012 Taobao.com. All rights reserved.
//

#import "Client.h"

@implementation Client
@synthesize outputStream;
@synthesize inputStream;
@synthesize sock_fd;

- (void)dealloc{
    [self setOutputStream:nil];
    [self setInputStream:nil];
    [super dealloc];
}
@end
