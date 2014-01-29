//
//  NSStream+remoteHost.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/28/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "NSStream+remoteHost.h"

@implementation NSStream (remoteHost)

+(void)getStreamsToHost:(NSString *)host
                   port:(NSString *)port
            inputStream:(NSInputStream **)inputstream
           outputStream:(NSOutputStream **)outputstream
{
    CFReadStreamRef readStream; // input
    CFWriteStreamRef writeStream; // output
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge_retained CFStringRef)host, [port integerValue], &readStream, &writeStream);
    *inputstream = (__bridge_transfer NSInputStream*)readStream;
    *outputstream = (__bridge_transfer NSOutputStream*)writeStream;
}

@end
