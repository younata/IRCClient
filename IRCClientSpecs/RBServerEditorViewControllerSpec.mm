#import "RBServerEditorViewController.h"
#import "RBIRCServer.h"
#import "RBConfigurationKeys.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBServerEditorViewControllerSpec)

describe(@"RBServerEditorViewController", ^{
    __block RBServerEditorViewController *subject;
    __block RBIRCServer *server;
    
    void (^sendTarget)(UIBarButtonItem *) = ^(UIBarButtonItem *bbi) {
        SEL act = [bbi action];
        id target = [bbi target];
        [target performSelector:act withObject:bbi];
    };

    beforeEach(^{
        subject = [[RBServerEditorViewController alloc] init];
        server = nice_fake_for([RBIRCServer class]);
        server.writeStream = nice_fake_for([NSOutputStream class]);
        server.readStream = nice_fake_for([NSInputStream class]);
        subject.server = server;
        
        spy_on(subject);
    });
    
    it(@"should name things correctly", ^{
        [subject view];
        subject.cancelButton.title should equal(@"Cancel");
    });
    
    it(@"should be invalid", ^{
        [subject view];
        subject.validateInfo should be_falsy;
        subject.saveButton.enabled should be_falsy;
    });
    
    it(@"should do nothing on cancel", ^{
        [subject view];
        sendTarget(subject.cancelButton);
        
        subject should_not have_received("save");
    });
    
    it(@"should write any changes to standard user defaults", ^{
        [[RBDataManager sharedInstance] removeEverything];
        server = [[RBIRCServer alloc] init];
        [server configureWithHostname:@"localhost"
                                  ssl:YES
                                 port:@"6697"
                                 nick:@"testnick"
                             realname:@"testnick"
                             password:nil];
        subject.server = server;
        [subject view];
        [subject viewDidLoad];
        subject.saveButton.enabled = YES;
        [subject save];
        Server *theServer = [[RBDataManager sharedInstance] serverWithProperty:server.hostname propertyName:@"host"];
        theServer.nick should equal(server.nick);
    });
    
    describe(@"when connecting to a new server", ^{
        beforeEach(^{
            server stub_method("connected").and_return(NO);
            [subject view];
            
            server stub_method("connect");
            server stub_method("connect:");
            server stub_method("connect:withPassword:");
            
            spy_on(server);
        });
        
        it(@"should enable everything", ^{
            [subject.saveButton title] should equal(@"Connect");
        });
        
        it(@"should not connect if no username is given", ^{
            sendTarget(subject.saveButton);
            subject should have_received("save");
            server should_not have_received("connect");
        });
        
        it(@"should connect on save", ^{
            server stub_method("nick").and_return(@"testusername");
            subject.server = subject.server;
            subject.saveButton.enabled = true;
            sendTarget(subject.saveButton);
            subject should have_received("save");
            server should have_received("connect");
        });
    });
    
    describe(@"when editing an existing server", ^{
        beforeEach(^{
            server stub_method("connected").and_return(YES);
            [subject view];
        });
        
        it(@"should title the connect button 'Save'", ^{
            [subject.saveButton title] should equal(@"Save");
        });
    });
});

SPEC_END
