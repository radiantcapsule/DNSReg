//
//  BonjourController.h
//  DNSReg
//
//  Created by Alex Vollmer on 11/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <dns_sd.h>

@interface BonjourController : NSObject
{
	DNSServiceRef       fServiceRef;
	CFSocketRef         fSocketRef;
	CFRunLoopSourceRef  fRunloopSrc;
}

- (id)initWithServiceRef:(DNSServiceRef)ref;
- (void)addToCurrentRunLoop;
- (DNSServiceRef)serviceRef;
- (void)dealloc;

@end
