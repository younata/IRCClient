#import "RBNameViewController.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBNameViewControllerSpec)

describe(@"RBNameViewController", ^{
    __block RBNameViewController *subject;
    __block NSArray *names;

    beforeEach(^{
        subject = [[RBNameViewController alloc] init];
        names = @[@"jercos", @"abzde", @"jmkogut", @"You", @"morbidflight", @"_0x44", @"artemis", @"bawksphone", @"bradoaks",
                  @"chaos95", @"cinebox", @"cooper", @"dan", @"dipshit", @"Dritz", @"Ducky", @"emsenn", @"epsilon", @"Eugene",
                  @"freelancer", @"hannerz_", @"Hellow", @"hernerz", @"hintss", @"ik", @"instead", @"joannac", @"Laogeodritt",
                  @"LordCOTA", @"nameless", @"pr3fatum", @"Rbon", @"regentoforigin", @"Sigma", @"Suspect", @"TrueShiftBlue", @"Weyoun"];
        // why yes, I did just take the NAMES list of a channel I'm in....
        [subject view];
    });
    
    it(@"should list the names", ^{
        subject.names = [names mutableCopy];
        
        [subject numberOfSectionsInTableView:subject.tableView] should equal(1);
        [subject tableView:subject.tableView numberOfRowsInSection:0] should equal(names.count);
        
        NSMutableArray *m = [names mutableCopy];
        for (int row = 0; row < names.count; row++) {
            NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
            UITableViewCell *cell = [subject tableView:subject.tableView cellForRowAtIndexPath:path];
            NSString *name = cell.textLabel.text;
            [m containsObject:name] should be_truthy;
            [m removeObject:name];
        }
        m.count should equal(0);
    });
});

SPEC_END
