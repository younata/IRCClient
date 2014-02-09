#import "RBIRCChannel.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBIRCChannelSpec)

describe(@"RBIRCChannel", ^{
    __block RBIRCChannel *subject;
    static NSString *name = @"#test";

    beforeEach(^{
        subject = [[RBIRCChannel alloc] initWithName:name];
    });
    
    it(@"should default to connect on startup", ^{
        subject.connectOnStartup should be_truthy;
    });
    
    it(@"should handle loading from NSUserDefaults correctly", ^{
        NSData *d = [NSKeyedArchiver archivedDataWithRootObject:subject];
        RBIRCChannel *c = [NSKeyedUnarchiver unarchiveObjectWithData:d];
        [c isEqual:subject] should be_truthy;
        c.connectOnStartup should equal(subject.connectOnStartup);
    });
});

SPEC_END
