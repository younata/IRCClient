//
//  RBScript.m
//  IRCClient
//
//  Created by Rachel Brindle on 2/20/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBScript.h"
#import "RBScriptingService.h"

#import "Nu.h"

@implementation RBScript

+(NSString *)description
{
    return NSStringFromClass(self);
}

+(NSDictionary *)configurationItems
{
    return nil;
}

+(id)inheritedByClass:(NuClass *)newClass
{
    [[RBScriptingService sharedInstance] registerScript:[newClass wrappedClass]];
    return [[self superclass] inheritedByClass:newClass];
}

-(void)serverDidConnect:(RBIRCServer *)server{}
-(void)serverDidDisconnect:(RBIRCServer *)server{}
-(void)serverDidError:(RBIRCServer *)server{}
-(void)server:(RBIRCServer *)server didReceiveMessage:(RBIRCMessage *)message{}

-(void)channel:(RBIRCChannel *)channel didLogMessage:(RBIRCMessage *)message{}

-(void)serverListWasLoaded:(RBServerViewController *)serverList{}
-(void)serverList:(RBServerViewController *)serverList didCreateNewServerCell:(UITableViewCell *)cell{}
-(void)serverList:(RBServerViewController *)serverList didCreateServerCell:(UITableViewCell *)cell forServer:(RBIRCServer *)server{}
-(void)serverList:(RBServerViewController *)serverList didCreateChannelCell:(UITableViewCell *)cell forChannel:(RBIRCChannel *)channel{}
-(void)serverList:(RBServerViewController *)serverList didCreatePrivateCell:(UITableViewCell *)cell forPrivateConversation:(RBIRCChannel *)conversation{}
-(void)serverList:(RBServerViewController *)serverList didCreateNewChannelCell:(RBTextFieldServerCell *)cell{}

-(void)serverEditorWasLoaded:(RBServerEditorViewController *)serverEditor{}
-(void)serverEditor:(RBServerEditorViewController *)serverEditor didMakeChangesToServer:(RBIRCServer *)server{}
-(void)serverEditorWillBeDismissed:(RBServerEditorViewController *)serverEditor{}

-(void)channelViewWasLoaded:(RBChannelViewController *)channelView{}
-(void)channelView:(RBChannelViewController *)channelView didDisconnectFromChannel:(RBIRCChannel *)channel andServer:(RBIRCServer *)server{}
-(void)channelView:(RBChannelViewController *)channelView didSelectChannel:(RBIRCChannel *)channel andServer:(RBIRCServer *)server{}
-(void)channelView:(RBChannelViewController *)channelView willDisplayMessage:(RBIRCMessage *)message inView:(UIView *)view{}

@end
