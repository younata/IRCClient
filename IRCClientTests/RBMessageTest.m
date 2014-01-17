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
{
    NSString *test;
    RBIRCMessage *msg;
}

@end

@implementation RBMessageTest

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
    test = nil;
    msg = nil;
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}


-(void)testJoin
{
    test = @":foobar!foo@hide-ECFE1E4F.dsl.mindspring.com JOIN :#boats";
    msg = [[RBIRCMessage alloc] initWithRawMessage:test];
    XCTAssertEqualObjects(msg.message, nil, @"Join message test");
    XCTAssertEqualObjects(msg.from, @"foobar", @"Join from test");
    XCTAssertEqualObjects(msg.to, @"#boats", @"Join target test");
    XCTAssertEqualObjects(msg.command, @"JOIN", @"Join command test");
}

-(void)testPrivmsg
{
    test = @":ik!iank@hide-1664EBC6.iank.org PRIVMSG #boats :how are you";
    msg = [[RBIRCMessage alloc] initWithRawMessage:test];
    XCTAssertEqualObjects(msg.message, @"how are you", @"privmsg message test");
    XCTAssertEqualObjects(msg.from, @"ik", @"privmsg from test");
    XCTAssertEqualObjects(msg.to, @"#boats", @"privmsg target test");
    XCTAssertEqualObjects(msg.command, @"PRIVMSG", @"privmsg command test");
}

-(void)testNotice
{
    // NOTICE
    test = @":You!Rachel@hide-DEA18147.com NOTICE foobar :test";
    msg = [[RBIRCMessage alloc] initWithRawMessage:test];
    XCTAssertEqualObjects(msg.message, @"test", @"Notice message test");
    XCTAssertEqualObjects(msg.from, @"You", @"Notice from test");
    XCTAssertEqualObjects(msg.to, @"foobar", @"Notice target test");
    XCTAssertEqualObjects(msg.command, @"NOTICE", @"Notice command test");
}

-(void)testPart
{
    // PART
    test = @":You!Rachel@hide-DEA18147.com PART #foo :test";
    msg = [[RBIRCMessage alloc] initWithRawMessage:test];
    XCTAssertEqualObjects(msg.message, @"test", @"Part message test");
    XCTAssertEqualObjects(msg.from, @"You", @"Part from test");
    XCTAssertEqualObjects(msg.to, @"#foo", @"Part target test");
    XCTAssertEqualObjects(msg.command, @"PART", @"Part command test");
}
-(void)testMode
{
    // MODE
    test = @":You!Rachel@hide-DEA18147.com MODE #foo +b foobar!*@*"; // ban
    msg = [[RBIRCMessage alloc] initWithRawMessage:test];
    XCTAssertEqualObjects(msg.message, @"+b foobar!*@*", @"Mode message test");
    
    XCTAssert([msg.extra isKindOfClass:[NSArray class]], @"Kick Extra type");
    XCTAssertEqualObjects(msg.extra[0], @"+b", @"Kicked target test");
    XCTAssertEqualObjects(msg.extra[1], @"foobar!*@*", @"Kick reason test");
    
    XCTAssertEqualObjects(msg.from, @"You", @"Mode from test");
    XCTAssertEqualObjects(msg.to, @"#foo", @"Mode target test");
    XCTAssertEqualObjects(msg.command, @"MODE", @"Mode command test");
}
-(void)testKick
{
    // KICK
    test = @":You!Rachel@hide-DEA18147.com KICK #foo foobar :You";
    msg = [[RBIRCMessage alloc] initWithRawMessage:test];
    XCTAssertEqualObjects(msg.message, @"foobar :You", @"Kick message test");
    
    XCTAssert([msg.extra isKindOfClass:[NSDictionary class]], @"Kick Extra type");
    XCTAssertEqualObjects(msg.extra[@"target"], @"foobar", @"Kicked target test");
    XCTAssertEqualObjects(msg.extra[@"reason"], @"You", @"Kick reason test");
    
    XCTAssertEqualObjects(msg.from, @"You", @"Kick from test");
    XCTAssertEqualObjects(msg.to, @"#foo", @"Kick to test");
    XCTAssertEqualObjects(msg.command, @"KICK", @"Kick command test");
    
    // ... all of the response codes.
}

@end
