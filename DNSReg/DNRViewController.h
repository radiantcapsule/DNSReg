//
//  DNRViewController.h
//  DNSReg
//
//  Created by Alex Vollmer on 11/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <dns_sd.h>

@interface DNRViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    @private
    DNSServiceRef   serviceRef_;
    CFSocketRef     socketRef_;
    CFRunLoopRef    runLoopRef_;
}

@property (retain, nonatomic) IBOutlet UITableView *tableView;

@end
