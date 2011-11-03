//
//  DNRResolveViewController.h
//  DNSReg
//
//  Created by Alex Vollmer on 11/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DNSRecord;

@interface DNRResolveViewController : UIViewController

@property (nonatomic, copy) NSString *myPeerID;
@property (nonatomic, retain) DNSRecord *peer;

@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutlet UILabel *hostLabel;
@property (retain, nonatomic) IBOutlet UILabel *portLabel;
@property (retain, nonatomic) IBOutlet UILabel *errorLabel;

- (id)initWithMyPeerID:(NSString *)peerID peer:(DNSRecord *)peerRecord;

@end
