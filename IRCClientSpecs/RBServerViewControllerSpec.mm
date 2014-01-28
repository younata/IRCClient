#import "RBServerViewController.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBServerViewControllerSpec)

describe(@"RBServerViewController", ^{
    __block RBServerViewController *subject;

    beforeEach(^{
        subject = [[RBServerViewController alloc] init];
        [subject view];
    });
    
    it(@"should have 1 default cell, for a new server.", ^{
        [subject numberOfSectionsInTableView:subject.tableView] should equal(1);
        [subject tableView:subject.tableView numberOfRowsInSection:0] should equal(1);
        UITableViewCell *cell = [subject tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        cell.textLabel.text should equal(@"New Server");
    });
});

SPEC_END
