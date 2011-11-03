//
//  DNRResolveViewController.m
//  DNSReg
//
//  Created by Alex Vollmer on 11/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <dns_sd.h>

#import "DNRResolveViewController.h"
#import "DNSRecord.h"
#import "BonjourController.h"

static void ResolveCallback(
                            DNSServiceRef                       sdRef,
                            DNSServiceFlags                     flags,
                            uint32_t                            interfaceIndex,
                            DNSServiceErrorType                 errorCode,
                            const char                          *fullname,
                            const char                          *hosttarget,
                            uint16_t                            port,        /* In network byte order */
                            uint16_t                            txtLen,
                            const unsigned char                 *txtRecord,
                            void                                *context
                            );

@interface DNRResolveViewController ()

@property (nonatomic, retain) BonjourController *resolveController;

- (void)updatePeerWithHost:(NSString *)host port:(uint16_t)port;
- (void)updateErrorMessage:(NSString *)message;

@end


static void ResolveCallback(
                            DNSServiceRef                       sdRef,
                            DNSServiceFlags                     flags,
                            uint32_t                            interfaceIndex,
                            DNSServiceErrorType                 errorCode,
                            const char                          *fullname,
                            const char                          *hosttarget,
                            uint16_t                            port,        /* In network byte order */
                            uint16_t                            txtLen,
                            const unsigned char                 *txtRecord,
                            void                                *context
                            )
{
    DNRResolveViewController *controller = (DNRResolveViewController *)context;
    if (errorCode == kDNSServiceErr_NoError) {
        [controller updatePeerWithHost:[NSString stringWithCString:hosttarget encoding:NSUTF8StringEncoding] port:ntohs(port)];
    }
    else {
        [controller updateErrorMessage:[NSString stringWithFormat:@"Failed to resolve peer: %i", errorCode]];
    }
}


@implementation DNRResolveViewController

@synthesize peer;
@synthesize titleLabel;
@synthesize hostLabel;
@synthesize portLabel;
@synthesize errorLabel;
@synthesize myPeerID;
@synthesize resolveController;

- (void)dealloc {
    [peer release];
    [myPeerID release];
    [titleLabel release];
    [hostLabel release];
    [portLabel release];
    [errorLabel release];
    [resolveController release];
    [super dealloc];
}

- (id)initWithMyPeerID:(NSString *)peerID peer:(DNSRecord *)peerRecord
{
    if ((self = [super initWithNibName:@"DNRResolveViewController" bundle:nil])) {
        self.myPeerID = peerID;
        self.peer = peerRecord;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Peer Resolution";
}

- (void)viewDidUnload
{
    [self setTitleLabel:nil];
    [self setHostLabel:nil];
    [self setPortLabel:nil];
    [self setErrorLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.titleLabel.text = [NSString stringWithFormat:@"Peer ID: %@", self.peer.name];
    
    DNSServiceRef serviceRef;
    DNSServiceErrorType error = DNSServiceResolve(&serviceRef, 
                                                  kDNSServiceFlagsIncludeP2P, 
                                                  kDNSServiceInterfaceIndexAny, 
                                                  self.peer.name.UTF8String, 
                                                  self.peer.regtype.UTF8String, 
                                                  self.peer.domain.UTF8String, 
                                                  ResolveCallback, 
                                                  self);
    
    if (kDNSServiceErr_NoError == error) {
        self.resolveController = [[[BonjourController alloc] initWithServiceRef:serviceRef] autorelease];
        [self.resolveController addToCurrentRunLoop];
    }
    else {
        NSString *message = [NSString stringWithFormat:@"Unable to register for DNS resolution: %i", error];
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"DNSServiceResolve()" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
        [alert show];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Properties

- (void)setMyPeerID:(NSString *)peerID
{
    self.titleLabel.text = [NSString stringWithFormat:@"My ID: %@", peerID];
}

- (void)updatePeerWithHost:(NSString *)host port:(uint16_t)port
{
    self.hostLabel.text = host;
    self.portLabel.text = [[NSNumber numberWithInt:port] stringValue];
}

- (void)updateErrorMessage:(NSString *)message
{
    self.errorLabel.text = message;
}

@end
