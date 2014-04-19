#import "RBConfigViewController.h"

#import "RBReconnectViewController.h"
#import "RBScriptingService.h"

#import "NSString+isNilOrEmpty.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBConfigViewControllerSpec)

describe(@"RBConfigViewController", ^{
    __block RBConfigViewController *subject;
    __block UINavigationController *navController;
    
    [[RBScriptingService sharedInstance] loadScripts];

    beforeEach(^{
        subject = [[RBConfigViewController alloc] init];
        navController = [[UINavigationController alloc] initWithRootViewController:subject];
        [subject view];
    });
    
    it(@"should have at least 3 sections", ^{
        [subject.tableView numberOfSections] should be_gte(3);
    });
    
    describe(@"Reconnect Section", ^{
        it(@"should have 1 row", ^{
            [subject.tableView numberOfRowsInSection:0] should equal(1);
        });
        
        it(@"should have no section title", ^{
            [subject.tableView.dataSource tableView:subject.tableView titleForHeaderInSection:0] should equal(@"");
        });
        
        it(@"should have a single cell", ^{
            UITableViewCell *reconcell = [subject.tableView.dataSource tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            reconcell should_not be_nil;
            reconcell.textLabel.text should equal(@"Connect on Startup");
        });
    });
    
    describe(@"CTCP Section", ^{
        it(@"should have 2 rows", ^{
            [subject.tableView numberOfRowsInSection:1] should equal(2);
        });
        
        it(@"should a section title", ^{
            [subject.tableView.dataSource tableView:subject.tableView titleForHeaderInSection:1] should equal(@"CTCP Responses");
        });
        
        it(@"should have 2 cells with textfields", ^{
            UITableViewCell *ctcpcellFinger = [subject.tableView.dataSource tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
            ctcpcellFinger.textLabel.text should equal(@"Finger");
            ctcpcellFinger.accessoryView should be_instance_of([UITextField class]);
            
            UITableViewCell *ctcpcellUserinfo = [subject.tableView.dataSource tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
            ctcpcellUserinfo.textLabel.text should equal(@"UserInfo");
            ctcpcellFinger.accessoryView should be_instance_of([UITextField class]);

        });
    });
    
    describe(@"Scripting secton", ^{
        beforeEach(^{
            [[RBScriptingService sharedInstance] runEnabledScripts];
        });
        
        it(@"should at least 1 row", ^{
            [subject.tableView numberOfRowsInSection:2] should be_gte(1);
        });
        
        it(@"should a section title", ^{
            [subject.tableView.dataSource tableView:subject.tableView titleForHeaderInSection:2] should equal(@"Extensions");
        });
        
        it(@"should have at least 1 cell with a switch", ^{
            UITableViewCell *scriptCell = [subject.tableView.dataSource tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
            scriptCell.textLabel.text should equal([[RBScriptingService sharedInstance] scripts][0]);
            scriptCell.accessoryView should be_instance_of([UISwitch class]);
        });
    });
    
    describe(@"Inline Images section", ^{
        // later...
    });
    
    describe(@"Experimental section", ^{
        it(@"should a section title", ^{
            [subject tableView:subject.tableView titleForHeaderInSection:4] should equal(@"Experimental");
        });
        
        it(@"should have at least 1 row", ^{
            [subject tableView:subject.tableView numberOfRowsInSection:4] should be_gte(1);
        });
        
        describe(@"first cell", ^{
            __block UITableViewCell *cell;
            beforeEach(^{
                cell = [subject tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:4]];
            });
            
            it(@"should be for keyboards", ^{
                cell.textLabel.text should equal(@"Keyboards");
            });

            
            it(@"should be disabled on iPhones", ^{
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                    cell.textLabel.textColor should equal([UIColor lightGrayColor]);
                    [subject tableView:subject.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:4]];
                    // still no idea how to describe a LACK of behavior...
                } else {
                    [subject tableView:subject.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:4]];
                    // should present a new view controller...
                }
            });
        });
    });
});

SPEC_END
