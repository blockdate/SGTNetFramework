//
//  SGTNetworking+RACSupport.h
//  SGTFoundation
//
//  Created by 磊吴 on 16/5/12.
//  Copyright © 2016年 block. All rights reserved.
//

#import "SGTNetworking.h"
#import <AFURLRequestSerialization.h>

@class RACSignal;

@interface SGTNetworking (RACSupport)


/**
 @author block, 16-05-12 17:05:27
 
 @brief RAC GET请求
 
 @param path       请求的相对或绝对路径
 @param parameters 请求参数
 
 @return 返回信号，next信号量为RACTuple，fitst为json对象，second为httpResponse。error信号量为NSError
 */
+ (RACSignal *)rac_GET:(NSString *)path parameters:(id)parameters;

/**
 @author block, 16-05-12 17:05:27
 
 @brief RAC HEAD请求
 
 @param path       请求的相对或绝对路径
 @param parameters 请求参数
 
 @return 返回信号，next信号量为RACTuple，fitst为json对象，second为httpResponse。error信号量为NSError
 */
+ (RACSignal *)rac_HEAD:(NSString *)path parameters:(id)parameters;

/**
 @author block, 16-05-12 17:05:27
 
 @brief RAC POST请求
 
 @param path       请求的相对或绝对路径
 @param parameters 请求参数
 
 @return 返回信号，next信号量为RACTuple，fitst为json对象，second为httpResponse。error信号量为NSError
 */
+ (RACSignal *)rac_POST:(NSString *)path parameters:(id)parameters;

/**
 @author block, 16-05-12 17:05:24
 
 @brief RAC POST请求
 
 @param path       请求的相对或绝对路径
 @param parameters 请求参数
 @param block      上传文件数据拼接block
 
 @return 返回信号，next信号量为RACTuple，fitst为json对象，second为httpResponse。error信号量为NSError
 */
+ (RACSignal *)rac_POST:(NSString *)path parameters:(id)parameters constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block;

/**
 @author block, 16-05-12 17:05:27
 
 @brief RAC PUT请求
 
 @param path       请求的相对或绝对路径
 @param parameters 请求参数
 
 @return 返回信号，next信号量为RACTuple，fitst为json对象，second为httpResponse。error信号量为NSError
 */
+ (RACSignal *)rac_PUT:(NSString *)path parameters:(id)parameters;

/**
 @author block, 16-05-12 17:05:27
 
 @brief RAC Post请求
 
 @param path       请求的相对或绝对路径
 @param parameters 请求参数
 
 @return 返回信号，next信号量为RACTuple，fitst为json对象，second为httpResponse。error信号量为NSError
 */
+ (RACSignal *)rac_PATCH:(NSString *)path parameters:(id)parameters;

/**
 @author block, 16-05-12 17:05:27
 
 @brief RAC DELETE请求
 
 @param path       请求的相对或绝对路径
 @param parameters 请求参数
 
 @return 返回信号，next信号量为RACTuple，fitst为json对象，second为httpResponse。error信号量为NSError
 */
+ (RACSignal *)rac_DELETE:(NSString *)path parameters:(id)parameters;

@end
