//
//  DNSRecord.h
//  DNSReg
//
//  Created by Alex Vollmer on 11/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DNSRecord : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *regtype;
@property (nonatomic, assign) uint16_t port;
@property (nonatomic, assign) uint32_t interfaceIndex;
@property (nonatomic, copy) NSString *domain;

@end
