//
//  NSFileManager+pathMethod.h
//
//  Created by block on 14-9-22.
//  Copyright (c) 2014年 Block. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (pathMethod)
/**
 *  判断文件存在时间是否超过时限
 *
 *  @param path 文件路径
 *  @param time 上限时长
 *
 *  @return 是否超时
 */
+(BOOL)sgt_isTimeOutWithPath:(NSString *)path time:(NSTimeInterval)time;

+(long long)sgt_fileSizeAt:(NSString *)path;

+ (NSTimeInterval)sgt_fileExistTime:(NSString *)path;

@end
