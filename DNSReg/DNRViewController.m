//
//  DNRViewController.m
//  DNSReg
//
//  Created by Alex Vollmer on 11/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DNRViewController.h"
#import "DNRResolveViewController.h"
#import "DNSRecord.h"

#pragma mark - Function prototypes

static void RegistrationCallback(
                                 DNSServiceRef                       sdRef,
                                 DNSServiceFlags                     flags,
                                 DNSServiceErrorType                 errorCode,
                                 const char                          *name,
                                 const char                          *regtype,
                                 const char                          *domain,
                                 void                                *context
                                 );

static void BrowseCallback(
                           DNSServiceRef                       sdRef,
                           DNSServiceFlags                     flags,
                           uint32_t                            interfaceIndex,
                           DNSServiceErrorType                 errorCode,
                           const char                          *serviceName,
                           const char                          *regtype,
                           const char                          *replyDomain,
                           void                                *context
                           );

static void ProcessSocketResult(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

#pragma mark - Private DNRViewController category

@interface DNRViewController ()

@property (nonatomic, retain) NSMutableArray *peerServices;    
@property (nonatomic, retain) NSString *peerID;

- (void)start;
- (void)stop;
- (void)addPeer:(DNSRecord *)peer;
- (void)removePeer:(DNSRecord *)peer;

@end

#pragma mark - DNS-SD callback functions

static void RegistrationCallback(
                                 DNSServiceRef                       sdRef,
                                 DNSServiceFlags                     flags,
                                 DNSServiceErrorType                 errorCode,
                                 const char                          *name,
                                 const char                          *regtype,
                                 const char                          *domain,
                                 void                                *context
                                 )
{
    if (errorCode == kDNSServiceErr_NoError) {
        NSLog(@"Hello, we've been called-back for registration");
    }
    else {
        NSString *message = [NSString stringWithFormat:@"Unexpected error code: %i", errorCode];
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Registration Callback Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
        [alert show];
    }
}

static void BrowseCallback(
                           DNSServiceRef                       sdRef,
                           DNSServiceFlags                     flags,
                           uint32_t                            interfaceIndex,
                           DNSServiceErrorType                 errorCode,
                           const char                          *serviceName,
                           const char                          *regtype,
                           const char                          *replyDomain,
                           void                                *context
                           )
{
    DNRViewController *controller = (DNRViewController *)context;
    if (errorCode == kDNSServiceErr_NoError) {
        NSString *peerName = [NSString stringWithCString:serviceName encoding:NSUTF8StringEncoding];
        // ignore discovering ourselves
        if ([peerName isEqualToString:controller.peerID]) {
            return;
        }

        DNSRecord *record = [[[DNSRecord alloc] init] autorelease];
        record.name = [NSString stringWithCString:serviceName encoding:NSUTF8StringEncoding];
        record.regtype = [NSString stringWithCString:regtype encoding:NSUTF8StringEncoding];
        record.domain = [NSString stringWithCString:replyDomain encoding:NSUTF8StringEncoding];
        record.interfaceIndex = interfaceIndex;

        if (flags & kDNSServiceFlagsAdd) {
            [controller addPeer:record];
        }
        else {
            [controller removePeer:record];
        }
    }
    else {
        NSLog(@"%s unable to browse: %i", __PRETTY_FUNCTION__, errorCode);
    }
}

static void ProcessSocketResult(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    DNSServiceErrorType error = DNSServiceProcessResult((DNSServiceRef)info);
    if (error == kDNSServiceErr_NoError) {
        NSLog(@"%s, result processed successfully", __PRETTY_FUNCTION__);
    }
    else {
        NSLog(@"%s result failed to process: %i", __PRETTY_FUNCTION__, error);
    }
}

#pragma mark - DNRViewController implementation

@implementation DNRViewController

@synthesize tableView = tableView_;
@synthesize peerServices = peerServices_;
@synthesize peerID = peerID_;

- (void)dealloc
{
    [self stop];
 
    self.peerID = nil;
    self.peerServices = nil;
    
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
    self.tableView = nil;

    if (self->serviceRef_) {
        DNSServiceRefDeallocate(self->serviceRef_);
        self->serviceRef_ = NULL;
    }
    
    if (self->socketRef_) {
        CFSocketInvalidate(self->socketRef_);
        CFRelease(self->socketRef_);
        self->socketRef_ = NULL;
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.peerServices = [NSMutableArray array];

        // create a unique peer ID
        CFUUIDRef UUID = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef UUIDString = CFUUIDCreateString(kCFAllocatorDefault,UUID);
        self.peerID = [NSString stringWithString:(NSString *)UUIDString];
        CFRelease(UUIDString);
        CFRelease(UUID);
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"DNS-SD Magic";
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self start];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    [self stop];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - DNS-SD stuff

- (void)start
{
    // 1. register this service
    DNSServiceErrorType error;
    error = DNSServiceRegister(&self->serviceRef_, 
                               kDNSServiceFlagsIncludeP2P, 
                               kDNSServiceInterfaceIndexAny, 
                               self.peerID.UTF8String,
                               "_bananas._tcp.", 
                               NULL,
                               NULL, 
                               5150, 
                               0, 
                               NULL, 
                               RegistrationCallback, 
                               self);

    if (error) {
        NSString *message = [NSString stringWithFormat:@"Unable to register record: %i", error];
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"DNS-SD Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
        [alert show];
        return;
    }
    
    // 2. Now start browsing
    error = DNSServiceBrowse(&self->serviceRef_, 
                             kDNSServiceFlagsIncludeP2P, 
                             kDNSServiceInterfaceIndexAny, 
                             "_bananas._tcp.", 
                             NULL, 
                             BrowseCallback, 
                             self);
    
    if (error) {
        NSString *message = [NSString stringWithFormat:@"Unable to setup browsing: %i", error];
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"DNS-SD Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
        [alert show];
        return;
    }
    
    // finally, get the DNS-SD socket and stick it in a run-loop to continue processing
    int fd = DNSServiceRefSockFD(self->serviceRef_);
    CFSocketContext context = { 0, self->serviceRef_, NULL, NULL, NULL };
    self->socketRef_ = CFSocketCreateWithNative(kCFAllocatorDefault, fd, kCFSocketReadCallBack, ProcessSocketResult, &context);
    if (self->socketRef_) {
        CFRunLoopSourceRef rls = CFSocketCreateRunLoopSource(kCFAllocatorDefault, self->socketRef_, 0);
        if (rls) {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
            CFRelease(rls);
        }
        else {
            NSLog(@"Unable to create run-loop source");
        }
    }
    else {
        NSLog(@"Unable to create a socket reference to the DNS-SD daemon");
    }
}

- (void)stop
{
    // TODO: implement me!
}

- (void)addPeer:(DNSRecord *)peer
{
    if ([self.peerServices indexOfObject:peer] == NSNotFound) {
        [self.peerServices addObject:peer];
        [self.tableView reloadData];
    }
}

- (void)removePeer:(DNSRecord *)peer
{
    [self.peerServices removeObject:peer];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.peerServices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"CellIdentifier";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    
    DNSRecord *record = [self.peerServices objectAtIndex:indexPath.row];                    
    cell.textLabel.text = record.name;

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"My ID: %@", self.peerID];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    DNSRecord *record = [self.peerServices objectAtIndex:indexPath.row];

    DNRResolveViewController *vc = [[[DNRResolveViewController alloc] initWithMyPeerID:self.peerID peer:record] autorelease];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
