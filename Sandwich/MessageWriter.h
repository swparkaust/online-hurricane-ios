//
//  MessageWriter.h
//  OnlineSandwiches
//
//  Created by Sunwoo Park on 2/23/15.
//  Copyright (c) 2015 Ryuhyun Factory. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MessageWriter : NSObject {
    NSMutableData * _data;
}

@property (retain, readonly) NSMutableData * data;

- (void)writeByte:(unsigned char)value;
- (void)writeInt:(int)value;
- (void)writeString:(NSString *)value;

@end
