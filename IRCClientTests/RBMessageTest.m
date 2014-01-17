//
//  RBMessageTest.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RBIRCMessage.h"

@interface RBMessageTest : XCTestCase

@end

@implementation RBMessageTest

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}


-(void)parseMessage
{
    NSString *test;
    RBIRCMessage *msg;
    
    // JOIN
    test = @":foobar!foo@hide-ECFE1E4F.dsl.mindspring.com JOIN :#boats";
    msg = [[RBIRCMessage alloc] initWithRawMessage:test];
    XCTAssertEqualObjects(msg.message, @"#boats", @"Join message test");
    XCTAssertEqualObjects(msg.from, @"foobar", @"Join from test");
    XCTAssertEqualObjects(msg.to, @"", @"Join target test");
    XCTAssertEqualObjects(msg.command, @"JOIN", @"Join command test");
    
    // PRIVMSG
    test = @":ik!iank@hide-1664EBC6.iank.org PRIVMSG #boats :how are you";
    msg = [[RBIRCMessage alloc] initWithRawMessage:test];
    XCTAssertEqualObjects(msg.message, @"how are you", @"privmsg message test");
    XCTAssertEqualObjects(msg.from, @"ik", @"privmsg from test");
    XCTAssertEqualObjects(msg.to, @"#boats", @"privmsg target test");
    XCTAssertEqualObjects(msg.command, @"PRIVMSG", @"privmsg command test");
    
    // NOTICE
    
    // PART
    
    // MODE
    
    // ... all of the response codes.
}

@end
