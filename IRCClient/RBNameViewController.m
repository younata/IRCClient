#import "RBNameViewController.h"

#import "RBDataManager.h"

#import "Nick.h"
#import "Server.h"
#import "RBIRCServer.h"

@interface RBNameViewController () <UIAlertViewDelegate>

@property (nonatomic, strong) Server *dataServer;
@property (nonatomic, strong) NSDictionary *buttonTitles;

@end

static NSString *CellIdentifier = @"Cell";

@implementation RBNameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
}

- (void)setServerName:(NSString *)serverName
{
    _serverName = serverName.copy;
    
    self.dataServer = [[RBDataManager sharedInstance] serverForServerName:serverName];
}

- (void)setNames:(NSMutableArray *)names
{
    NSMutableArray *n = [[NSMutableArray alloc] initWithCapacity:names.count];
    for (NSString *user in names) {
        [n addObject:[user stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"+%@&~"]]];
    }
    _names = n;
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.names.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSString *nickName = self.names[indexPath.row];
    cell.textLabel.text = nickName;
    cell.textLabel.textAlignment = NSTextAlignmentRight;
    
    Nick *nick = [[RBDataManager sharedInstance] nick:nickName onServer:self.dataServer];
    if (nick) {
        cell.textLabel.textColor = nick.color;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.actionSheet) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        return;
    }
    
    NSString *name = self.names[indexPath.row];
    
    // kick, mode, private message, ctcp
    
    NSString *kick = [NSString localizedStringWithFormat:NSLocalizedString(@"Kick %@", nil), name];
    NSString *mode = NSLocalizedString(@"Change Mode", nil);
    NSString *privmsg = NSLocalizedString(@"Send Private Message", nil);
    NSString *ctcp = NSLocalizedString(@"Send CTCP", nil);
    
    self.buttonTitles = @{kick: @"kick",
                          mode: @"mode",
                          privmsg: @"privmsg",
                          ctcp: @"ctcp",
                          };
    
    self.actionSheet = [[UIActionSheet alloc] initWithTitle:name
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:kick, mode, privmsg, ctcp, nil];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    void (^deselect)() = ^{
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
        self.actionSheet = nil;
    };
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        deselect();
        return;
    }
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    NSString *user = self.names[[self.tableView indexPathForSelectedRow].row];
    
    NSString *cancel = NSLocalizedString(@"Cancel", nil);
    
    if ([actionSheet.title isEqualToString:user]) {
        NSString *action = self.buttonTitles[title];
        if ([action isEqualToString:@"kick"]) {
            // (try to) kick the user.
            [self.server kick:user target:@""];
            
            deselect();
        } else if ([action isEqualToString:@"privmsg"]) {
            // input in "/action %@ " to the channel view and give it first responder.
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString localizedStringWithFormat:NSLocalizedString(@"Private Message to %@", nil), user]
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:cancel
                                                      otherButtonTitles:NSLocalizedString(@"Send", nil),nil];
            alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alertView show];
        } else if ([action isEqualToString:@"mode"]) {
            self.actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Set Mode", nil)
                                                           delegate:self
                                                  cancelButtonTitle:cancel
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:nil];
            self.actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
            
            // sop, op, hop, voice, ban, quiet ban
            
            for (NSString *str in @[
                                    //@"Super Op",
                                    @"Op",
                                    @"Half Op",
                                    @"Voice",
                                    @"Ban",
                                    //@"Quiet Ban"
                                    ]) {
                [self.actionSheet addButtonWithTitle:str];
            }
            
            [self.actionSheet showInView:self.view];
        } else if ([action isEqualToString:@"ctcp"]) {
            self.actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"CTCP Commands", nil)
                                                           delegate:self
                                                  cancelButtonTitle:cancel
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:nil];
            self.actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
            
            for (NSString *str in @[@"finger",
                                    @"version",
                                    @"source",
                                    @"userinfo",
                                    @"clientinfo",
                                    @"ping",
                                    @"time"]) {
                [self.actionSheet addButtonWithTitle:str];
            }
            
            [self.actionSheet showInView:self.view];
        }
    } else if ([actionSheet.title isEqualToString:NSLocalizedString(@"Set Mode", nil)]) {
        NSString *mode = title;
        
        NSString *command = @"";
        
        if ([mode isEqualToString:@"Super Op"]) {
            command = @"";
        } else if ([mode isEqualToString:@"Op"]) {
            command = @"+o";
        } else if ([mode isEqualToString:@"Half Op"]) {
            command = @"+h";
        } else if ([mode isEqualToString:@"Voice"]) {
            command = @"+v";
        } else if ([mode isEqualToString:@"Ban"]) {
            command = @"+b";
        } else if ([mode isEqualToString:@"Quiet Ban"]) {
            command = @"";
        }
        
        [self.server mode:user options:@[command]];
        
        deselect();
    } else if ([actionSheet.title isEqualToString:NSLocalizedString(@"CTCP Commands", nil)]) {
        NSString *str = [NSString stringWithFormat:@"%c%@%c", 1, title, 1];
        [self.server privmsg:user contents:str];
        
        deselect();
    }
}

#pragma mark - UIALertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView cancelButtonIndex] != buttonIndex) {
        NSString *msg = [alertView textFieldAtIndex:0].text;
        NSString *user = self.names[[self.tableView indexPathForSelectedRow].row];
        
        [self.server privmsg:user contents:msg];
    }
    self.actionSheet = nil;
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)alertViewCancel:(UIAlertView *)alertView
{
    self.actionSheet = nil;
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

@end
