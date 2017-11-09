//
//  MessageReader.h
//  OnlineSandwiches
//
//  Created by Sunwoo Park on 2/23/15.
//  Copyright (c) 2015 Ryuhyun Factory. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MessageReader : NSObject {
    NSData * _data;
    int _offset;
}

- (id)initWithData:(NSData *)data;

- (unsigned char)readByte;
- (int)readInt;
- (NSString *)readString;

@end
