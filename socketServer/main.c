//
//  main.c
//  socketServer
//
//  Created by Lu Kejin on 1/21/12.
//  Copyright (c) 2012 Taobao.com. All rights reserved.
//

#include <stdio.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <string.h>
#include <unistd.h>
int main (int argc, const char * argv[])
{
    struct sockaddr_in server_addr;
    server_addr.sin_len = sizeof(struct sockaddr_in);
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(11332);
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    bzero(&(server_addr.sin_zero),8);
    
    //创建socket
    int server_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server_socket == -1) {
        perror("socket error");
        return 1;
    }
    
    //绑定socket
    int bind_result = bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr));
    if (bind_result == -1) {
        perror("bind error");
        return 1;
    }
    
    //listen
    if (listen(server_socket, 5) == -1) {
        perror("listen error");
        return 1;
    }
    FD_ZERO();
    
    struct sockaddr_in client_address;
    socklen_t address_len;
    int client_socket = accept(server_socket, (struct sockaddr *)&client_address, &address_len);
    if (client_socket == -1) {
        perror("accept error");
        return -1;
    }
    
    char recv_msg[1024];
    char reply_msg[1024];
    
    while (1) {
        bzero(recv_msg, 1024);
        bzero(reply_msg, 1024);
        
        printf("reply:");
        scanf("%s",reply_msg);
        send(client_socket, reply_msg, 1024, 0);
        
        long byte_num = recv(client_socket,recv_msg,1024,0);
        recv_msg[byte_num] = '\0';
        printf("client said:%s\n",recv_msg);

    }
    
    close(client_socket);
    close(server_socket);
    
    return 0;
}

