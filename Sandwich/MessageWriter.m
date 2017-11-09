//
//  MessageWriter.m
//  OnlineSandwiches
//
//  Created by Sunwoo Park on 2/23/15.
//  Copyright (c) 2015 Ryuhyun Factory. All rights reserved.
//

#import "MessageWriter.h"

@implementation MessageWriter
@synthesize data = _data;

- (id)init {
    if ((self = [super init])) {
        _data = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)writeBytes:(void *)bytes length:(int)length {
    [_data appendBytes:bytes length:length];
}

- (void)writeByte:(unsigned char)value {
    [self writeBytes:&value length:sizeof(value)];
}

- (void)writeInt:(int)intValue {
    int value = htonl(intValue);
    [self writeBytes:&value length:sizeof(value)];
}

- (void)writeString:(NSString *)value {
    const char * utf8Value = [value UTF8String];
    int length = (int)strlen(utf8Value) + 1; // for null terminator
    [self writeInt:length];
    [self writeBytes:(void *)utf8Value length:length];
}

@end
