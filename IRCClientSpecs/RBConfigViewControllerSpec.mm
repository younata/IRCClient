#import "RBConfigViewController.h"

#import "RBReconnectViewController.h"

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
});

SPEC_END
