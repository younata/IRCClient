#import "RBServerViewController.h"
#import "RBIRCServer.h"
#import "RBIRCChannel.h"
#import "RBServerEditorViewController.h"
#import "RBServerVCDelegate.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBServerViewControllerSpec)

describe(@"RBServerViewController", ^{
    __block RBServerViewController *subject;

    beforeEach(^{
        subject = [[RBServerViewController alloc] init];
        [subject view];
        
        spy_on(subject.tableView);
        spy_on(subject);
    });
    
    it(@"should have 1 default cell, for a new server.", ^{
        [subject numberOfSectionsInTableView:subject.tableView] should equal(1);
        [subject tableView:subject.tableView numberOfRowsInSection:0] should equal(1);
        UITableViewCell *cell = [subject tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        cell.textLabel.text should equal(@"New Server");
    });
    
    it(@"should present an editor view controller when a new server is selected", ^{
        NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:0];
        [subject tableView:subject.tableView didSelectRowAtIndexPath:ip];
        subject should have_received(@selector(presentViewController:animated:completion:)).with(Arguments::any([RBServerEditorViewController class]), YES, nil);
        subject.tableView should have_received("deselectRowAtIndexPath:animated:").with(ip, Arguments::anything);
    });
    
    describe(@"server connections", ^{
        __block RBIRCChannel *c;
        beforeEach(^{
            RBIRCServer *s = nice_fake_for([RBIRCServer class]);
            c = [[RBIRCChannel alloc] initWithName:@"#foo"];
            s stub_method("serverName").and_return(@"Test Server");
            s stub_method("channels").and_return(@{@"#foo": c});
            [subject.servers addObject:s];
            [subject.tableView reloadData];
            
            subject.delegate = nice_fake_for(@protocol(RBServerVCDelegate));
            subject.delegate stub_method("server:didChangeChannel:").with(s, c);
            
            spy_on(subject.delegate);
        });
        
        it(@"should prepend servers to list", ^{
            [subject numberOfSectionsInTableView:subject.tableView] should be_gte(2);
            [subject tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].textLabel.text should equal(@"Test Server");
            [subject tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]].textLabel.text should equal(@"#foo");
            
            NSInteger i = [subject numberOfSectionsInTableView:subject.tableView];
            i should_not be_lte(1);
            [subject tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i-1]].textLabel.text should equal(@"New Server");
        });
        
        it(@"should present a server editor controller when the first cell in a server section is selected", ^{
            NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:0];
            [subject tableView:subject.tableView didSelectRowAtIndexPath:ip];
            subject should have_received(@selector(presentViewController:animated:completion:)).with(Arguments::any([RBServerEditorViewController class]), YES, nil);
            subject.tableView should have_received("deselectRowAtIndexPath:animated:").with(ip, Arguments::anything);
        });
        
        it(@"should change the current channel when a channel cell is selected", ^{
            NSIndexPath *ip = [NSIndexPath indexPathForRow:1 inSection:0];
            [subject tableView:subject.tableView didSelectRowAtIndexPath:ip];
            subject should_not have_received(@selector(presentViewController:animated:completion:));
            subject.delegate should have_received("server:didChangeChannel:").with(subject.servers[0], Arguments::anything);
            subject.tableView should have_received("deselectRowAtIndexPath:animated:").with(ip, Arguments::anything);

        });
    });
});

SPEC_END
