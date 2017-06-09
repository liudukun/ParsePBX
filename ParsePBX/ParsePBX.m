//
//  ParsePBX.m
//  ParsePBX
//
//  Created by liudukun on 2017/6/1.
//  Copyright © 2017年 liudukun. All rights reserved.
//

#import "ParsePBX.h"



@interface ParsePBX ()
{
    NSString *pbx;
    NSMutableDictionary *rootDic;
}
@end

@implementation ParsePBX

- (instancetype)init
{
    self = [super init];
    if (self) {
        rootDic = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (NSDictionary *)parsePBXFile:(NSString *)path{
    ParsePBX *px = [ParsePBX new];
    return [px parsePBXFile:path];
}

- (void)getPropertys{
    NSString *rootObjectID = rootDic[@"rootObject"];
    
    NSDictionary *objects = rootDic[@"objects"];
    NSDictionary *rootObject = objects[rootObjectID];
    NSString *targetID = rootObject[@"targets"][0];
    NSDictionary *target = objects[targetID];
    NSString *buildConfigurationListID = target[@"buildConfigurationList"];
    NSString *productName = target[@"productName"];
    NSString *targetName = target[@"name"];
    NSArray *buildConfigurations = objects[buildConfigurationListID][@"buildConfigurations"];
    
    [buildConfigurations enumerateObjectsUsingBlock:^(NSString  *configurationID, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *configuration = objects[configurationID];
        NSDictionary *buildSettings = configuration[@"buildSettings"];
        NSString *infopath = buildSettings[@"INFOPLIST_FILE"];
        NSString *configurationName = configuration[@"name"];
        NSLog(@"%@",configuration);
    }];
}


- (NSDictionary *)parsePBXFile:(NSString *)path{
    pbx = [NSString stringWithContentsOfFile:path usedEncoding:0 error:nil];
    
    pbx = [pbx stringByReplacingOccurrencesOfString:@"/\\*[^\\*/)]*\\*/" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, pbx.length)];
    pbx = [pbx stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    pbx = [pbx stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    pbx = [pbx stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    pbx = [pbx stringByReplacingOccurrencesOfString:@" " withString:@""];
    pbx = [pbx stringByReplacingOccurrencesOfString:@"//!$*UTF8*$!{" withString:@"root"];
    pbx = [pbx stringByAppendingString:@";"];
    //    NSLog(@"%@",pbx);
    
    NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:@"[^,\\{\\}\\[\\]]*=.*" options:0 error:nil];
    NSArray *arr = [reg matchesInString:pbx options:NSMatchingReportCompletion range:NSMakeRange(0, pbx.length)];
    [arr enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult  * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *str = [pbx substringWithRange:obj.range];
        NSString *rStr = [NSString stringWithFormat:@"\"%@\":",[str substringWithRange:NSMakeRange(0, obj.range.length -1)]];
        pbx =  [pbx stringByReplacingCharactersInRange:obj.range withString:rStr];
    }];
    

    [self startParse:pbx parent:rootDic];
//    NSLog(@"%@",rootDic);
    return rootDic;
    
    
}


- (void)startParse:(NSString *)string parent:(id)parent{
    int arrCount = 0,dicCount = 0,roll = 0,head = 0,end = 0,type = 0;
    if (!string.length) {
        return;
    }
    while (1) {
        if (roll > string.length - 1) {
            break;
        }
        NSString *rs = [string substringWithRange:NSMakeRange(roll, 1)];
        if ([rs isEqualToString:@"{"]) {
            dicCount++;
            
        }
        
        if ([rs isEqualToString:@"}"]) {
            dicCount--;
            type = 1;
            
        }
        
        if ([rs isEqualToString:@"("]) {
            arrCount++;
            
            
        }
        
        if ([rs isEqualToString:@")"]) {
            arrCount--;
            type = 2;
        }
        
        if ([rs isEqualToString:@";"]&&arrCount ==0 && dicCount ==0) {
            end = roll;
            NSString *sub = [string substringWithRange:NSMakeRange(head, end - head+1)];
            NSLog(@"%@",sub);
            [self subParse:sub parent:parent type:type];
            
            type = 0;
            head = roll + 1;
        }
        
        roll++;
    }
    
}

- (void)subParse:(NSString *)nodeString parent:(id)parent type:(int)type{
    
    if (type == 1) {
        NSRange rangeE = [nodeString rangeOfString:@"="];
        NSString *name = [nodeString substringToIndex:rangeE.location];
        NSRange rangeL = [nodeString rangeOfString:@"{"];
        NSString *valueString = [nodeString substringWithRange:NSMakeRange(rangeL.location + 1, nodeString.length - rangeL.location - 3)];
        NSMutableDictionary *tmp = [NSMutableDictionary dictionary];
        [parent setObject:tmp forKey:name];
        if ([self needParse:valueString]) {
            [self startParse:valueString parent:tmp];
        }
        
    }else if (type == 2) {
        
        NSRange rangeE = [nodeString rangeOfString:@"="];
        NSString *name = [nodeString substringToIndex:rangeE.location];
        NSRange rangeL = [nodeString rangeOfString:@"("];
        NSString *valueString = [nodeString substringWithRange:NSMakeRange(rangeL.location +1, nodeString.length - rangeL.location - 3)];
        NSArray *values = [valueString componentsSeparatedByString:@","];
        NSMutableArray *valuesM  = [NSMutableArray arrayWithArray:values];
        [values enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isEqualToString:@""]) {
                [valuesM removeObject:obj];
            }
        }];
        [parent setObject:valuesM forKey:name];
        
    }else{
        nodeString = [nodeString substringWithRange:NSMakeRange(0, nodeString.length -1)];
        NSArray *kv = [nodeString componentsSeparatedByString:@"="];
        NSString *v = [kv lastObject];
        NSString *k = [kv firstObject];
        [parent setObject:v forKey:k];
    }
    
    
}

- (BOOL)needParse:(NSString *)string{
    NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:@"=" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *arr = [reg matchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, string.length)];
    if (arr.count ==1) {
        return NO;
    }else{
        return YES;
    }
}

@end
