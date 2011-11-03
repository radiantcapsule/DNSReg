//
//  DNSRecord.m
//  DNSReg
//
//  Created by Alex Vollmer on 11/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DNSRecord.h"

@implementation DNSRecord

@synthesize name;
@synthesize regtype;
@synthesize port;
@synthesize interfaceIndex;
@synthesize domain;

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@:%x name=%@ regtype=%@ port=%i interfaceIndex=%i domain=%@>", NSStringFromClass([self class]), self, self.name, self.regtype, self.port, self.interfaceIndex, self.domain];
}

- (BOOL)isEqual:(id)object
{
  if (object) {
    if ([object isKindOfClass:[DNSRecord class]]) {
      DNSRecord *other = (DNSRecord *)object;
      return [self.name isEqualToString:other.name] && [self.regtype isEqualToString:other.regtype] && self.port == other.port && self.interfaceIndex == other.interfaceIndex && [self.domain isEqualToString:other.domain];
    }
  }
  return NO;
}

- (NSUInteger)hash
{
  return self.name.hash ^ self.regtype.hash ^ self.port ^ self.interfaceIndex ^ self.domain.hash;
}

@end
