//
//  NSStream+remoteHost.h
//  IRCClient
//
//  Created by Rachel Brindle on 1/28/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSStream (remoteHost)

+(void)getStreamsToHost:(NSString *)host
                   port:(NSString *)port
            inputStream:(NSInputStream **)inputstream
           outputStream:(NSOutputStream **)outputstream;

@end
