//
//  ServiceController.m
//  DNSReg
//
//  Created by Alex Vollmer on 11/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ServiceController.h"

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

@implementation ServiceController

- (id)initWithServiceRef:(DNSServiceRef)ref
{
	self = [super init];
  if (self) {
    fServiceRef = ref;
    fSocketRef = NULL;
    fRunloopSrc = NULL;
  }
	return self;
}


- (void)addToCurrentRunLoop
{
	CFSocketContext	context = { 0, (void*)fServiceRef, NULL, NULL, NULL };
  
	fSocketRef = CFSocketCreateWithNative(kCFAllocatorDefault, DNSServiceRefSockFD(fServiceRef), kCFSocketReadCallBack, ProcessSocketResult, &context);
	if (fSocketRef) {
    // Prevent CFSocketInvalidate from closing DNSServiceRef's socket.
    CFOptionFlags sockFlags = CFSocketGetSocketFlags(fSocketRef);
    CFSocketSetSocketFlags(fSocketRef, sockFlags & (~kCFSocketCloseOnInvalidate));
		fRunloopSrc = CFSocketCreateRunLoopSource(kCFAllocatorDefault, fSocketRef, 0);
  }
	if (fRunloopSrc) {
		CFRunLoopAddSource(CFRunLoopGetCurrent(), fRunloopSrc, kCFRunLoopDefaultMode);
  } else {
		printf("Could not listen to runloop socket\n");
  }
}


- (DNSServiceRef)serviceRef
{
	return fServiceRef;
}


- (void)dealloc
{
	if (fSocketRef) {
		CFSocketInvalidate(fSocketRef);		// Note: Also closes the underlying socket
		CFRelease(fSocketRef);
    
    // Workaround that gives time to CFSocket's select thread so it can remove the socket from its
    // FD set before we close the socket by calling DNSServiceRefDeallocate. <rdar://problem/3585273>
    usleep(1000);
	}
  
	if (fRunloopSrc) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), fRunloopSrc, kCFRunLoopDefaultMode);
		CFRelease(fRunloopSrc);
	}
  
	DNSServiceRefDeallocate(fServiceRef);
  
	[super dealloc];
}


@end // implementation ServiceController
