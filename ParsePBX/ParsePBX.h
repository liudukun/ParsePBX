//
//  ParsePBX.h
//  ParsePBX
//
//  Created by liudukun on 2017/6/1.
//  Copyright © 2017年 liudukun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ParsePBX : NSObject

+ (NSDictionary *)parsePBXFile:(NSString *)path;

@end
