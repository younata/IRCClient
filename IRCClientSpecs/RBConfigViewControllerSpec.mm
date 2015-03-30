#import "RBConfigViewController.h"

#import "NSString+isNilOrEmpty.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBConfigViewControllerSpec)

describe(@"RBConfigViewController", ^{
    __block RBConfigViewController *subject;
    __block UINavigationController *navController;

    beforeEach(^{
        subject = [[RBConfigViewController alloc] init];
        navController = [[UINavigationController alloc] initWithRootViewController:subject];
        [subject view];
    });
    
    it(@"should have at least 3 sections", ^{
        [subject.tableView numberOfSections] should be_gte(3);
    });
    
    describe(@"Nick Color Section", ^{
        it(@"should have 1 row", ^{
            [subject.tableView numberOfRowsInSection:0] should equal(1);
        });
        
        it(@"should have no section title", ^{
            [subject.tableView.dataSource tableView:subject.tableView titleForHeaderInSection:0] should equal(@"");
        });
        
        it(@"should have a single cell", ^{
            UITableViewCell *reconcell = [subject.tableView.dataSource tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            reconcell should_not be_nil;
            reconcell.textLabel.text should equal(@"Nick Colors");
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
    
    describe(@"Inline Images section", ^{
        // later...
    });
    
    describe(@"Experimental section", ^{
        it(@"should a section title", ^{
            [subject tableView:subject.tableView titleForHeaderInSection:4] should equal(@"Experimental");
        });
        
        it(@"should be empty (for now)", ^{
            [subject tableView:subject.tableView numberOfRowsInSection:4] should equal(0);
        });
    });
});

SPEC_END
