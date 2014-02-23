#import "RBScriptingService.h"
#import "RBConfigurationKeys.h"

#import "RBIRCChannel.h"
#import "RBIRCServer.h"
#import "RBIRCMessage.h"

#import "RBColorScheme.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBScriptingServiceSpec)

describe(@"RBScriptingService", ^{
    __block RBScriptingService *subject;
    
    [[RBScriptingService sharedInstance] loadScripts];

    beforeEach(^{
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:RBScriptLoad];
        subject = [RBScriptingService sharedInstance];
        [subject runEnabledScripts];
    });
    
    afterEach(^{
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:RBScriptLoad];
        [subject runEnabledScripts];
    });
    
    it(@"should not auto-load objects", ^{
        [[NSUserDefaults standardUserDefaults] objectForKey:RBScriptLoad] should be_instance_of([NSArray class]).or_any_subclass();
        subject.scriptSet.count should equal(0);
    });
    
    it(@"should have at least one script class", ^{
        subject.scriptDict.count should be_gte(1);
    });
    
    describe(@"Hilight script", ^{
        beforeEach(^{
            NSString *key = subject.scriptDict.allKeys[0];
            [[NSUserDefaults standardUserDefaults] setObject:@[key] forKey:RBScriptLoad];
            [subject runEnabledScripts];
        });
        
        it(@"should be the only loaded script", ^{
            subject.scriptSet.count should equal(1);
        });
        
        it(@"should highlight your nick only", ^{
            RBIRCServer *server = nice_fake_for([RBIRCServer class]);
            
            server stub_method("nick").and_return(@"You");
            
            RBIRCMessage *message = [[RBIRCMessage alloc] init];
            message.command = IRCMessageTypePrivmsg;
            message.message = @"hi You";
            message.targets = [@[@"#test"] mutableCopy];
            message.from = @"ik";
            
            NSAttributedString *str = message.attributedMessage;
            
            [subject messageLogged:message server:server];
            NSAttributedString *newStr = message.attributedMessage;
            str should_not equal(newStr);
            NSLog(@"Highlighted message: %@", newStr);
        });
    });
});

SPEC_END
