#import "RBScriptingService.h"
#import "RBConfigurationKeys.h"

#import "RBIRCChannel.h"
#import "RBIRCServer.h"
#import "RBIRCMessage.h"

#import "RBColorScheme.h"

#import "RBServerViewController.h"

#import "RBScript.h"
#import "NSObject+customProperty.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBScriptingServiceSpec)

describe(@"RBScriptingService", ^{
    __block RBScriptingService *subject;
    
    beforeEach(^{
        subject = [RBScriptingService sharedInstance];
        subject.runScriptsConcurrently = NO;
    });
    
    [[RBScriptingService sharedInstance] loadScripts];
});

SPEC_END
