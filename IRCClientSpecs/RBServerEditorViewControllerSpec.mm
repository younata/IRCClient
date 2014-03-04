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
        subject.server = server;
        
        spy_on(subject);
    });
    
    it(@"should name things correctly", ^{
        [subject view];
        [subject.cancelButton title] should equal(@"Cancel");
    });
    
    it(@"should always enable servername, nick, and connectOnStartup", ^{
        [subject view];
        subject.serverName.enabled should be_truthy;
        subject.serverName.enabled should be_truthy;
        subject.serverConnectOnStartup.enabled should be_truthy;
    });
    
    it(@"should do nothing on cancel", ^{
        [subject view];
        sendTarget(subject.cancelButton);
        
        subject should_not have_received("save");
    });
    
    it(@"should write any changes to standard user defaults", ^{
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:RBConfigServers];
        server = [[RBIRCServer alloc] initWithHostname:@"localhost"
                                                   ssl:YES
                                                  port:@"6697"
                                                  nick:@"testnick"
                                              realname:@"testnick"
                                              password:nil];
        subject.server = server;
        [subject view];
        [subject save];
        NSData *d = [[NSUserDefaults standardUserDefaults] objectForKey:RBConfigServers];
        NSArray *a = [NSKeyedUnarchiver unarchiveObjectWithData:d];
        a should_not be_empty;
        RBIRCServer *s = a.firstObject;
        [server isEqual:s] should be_truthy;
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
            subject.serverHostname.enabled should be_truthy;
            subject.serverPort.enabled should be_truthy;
            subject.serverSSL.enabled should be_truthy;
            subject.serverRealName.enabled should be_truthy;
            subject.serverPassword.enabled should be_truthy;
            [subject.saveButton title] should equal(@"Connect");
        });
        
        it(@"should not connect if no username is given", ^{
            sendTarget(subject.saveButton);
            subject should have_received("save");
            server should_not have_received("connect");
        });
        
        it(@"should connect on save", ^{
            server stub_method("nick").and_return(@"testusername");
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
