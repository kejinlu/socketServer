//
//  main.c
//  socketServer
//
//  Created by Lu Kejin on 1/21/12.
//  Copyright (c) 2012 Taobao.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatServer.h"

#include <stdio.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <string.h>


int main (int argc, const char * argv[])
{
    NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
    ChatServer *chatServer = [[[ChatServer alloc] init] autorelease];
    [chatServer run:NULL];
    [autoreleasePool release];
    return 0;
}

