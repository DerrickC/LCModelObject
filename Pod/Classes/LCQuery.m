// Created by Derrick Chao on 2015/5/6.
// Copyright (c) 2017 Loopd Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <AFNetworking/AFNetworking.h>
#import "LCModelObject+LocalStorage.h"
#import "LCQuery.h"
#import "LCSettings.h"

#define SettingsPlistFileName               @"LCModelObjectSettingsPlistFileName"
#define QueryDefaultHeaderFieldKey          @"QueryDefaultHeaderFieldKey"
#define QueryDefaultParametersKey           @"QueryDefaultParametersKey"
#define QueryCertFileNameKey                @"QueryCertFileNameKey"
#define QueryBaseURL                        @"QueryBaseURL"

@interface LCQuery ()

@end

@implementation LCQuery

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.parameters = [NSMutableDictionary new];
        self.header = [NSMutableDictionary new];
        self.timeoutInterval = 0;
    }
    
    return self;
}

#pragma mark - Init

+ (instancetype)query {
    return [[self class] queryWithRequestMethod:LCRequestMethodGET relatedPath:nil];
}

+ (instancetype)queryWithRequestMethod:(LCRequestMethod)requestMethod {
    return [[self class] queryWithRequestMethod:requestMethod relatedPath:nil];
}

+ (instancetype)queryWithRequestMethod:(LCRequestMethod)requestMethod relatedPath:(NSString *)relatedPath {
    return [[self class] queryWithRequestMethod:requestMethod relatedPath:relatedPath parameters:nil];
}

+ (instancetype)queryWithRequestMethod:(LCRequestMethod)requestMethod relatedPath:(NSString *)relatedPath parameters:(NSDictionary *)parameters {
    
    NSString *baseURL = [LCQuery baseURL];
    NSString *requestUrl;
    if ([relatedPath rangeOfString:@"http://"].location == NSNotFound && [relatedPath rangeOfString:@"https://"].location == NSNotFound) {
        // relative path
        requestUrl = [NSString stringWithFormat:@"%@%@", baseURL, relatedPath];
    } else {
        // absolute path
        requestUrl = relatedPath;
    }
    
    return [LCQuery queryWithRequestMethod:requestMethod url:requestUrl parameters:parameters];
}

+ (instancetype)queryWithRequestMethod:(LCRequestMethod)requestMethod url:(NSString *)url parameters:(NSDictionary *)parameters {
    return [[LCQuery alloc] initWithRequestMethod:requestMethod url:url parameters:parameters];
}

- (instancetype)initWithRequestMethod:(LCRequestMethod)requestMethod url:(NSString *)url parameters:(NSDictionary *)parameters {
    
    self = [self init];
    
    if (self) {
        self.requestMethod = requestMethod;
        self.requestUrl = url;
        if (parameters) {
            [self.parameters setDictionary:parameters];
        }
    }
    
    return self;
}

#pragma mark - Class Method

+ (void)setBaseURL:(NSString *)baseURL {
    [LCSettings setSetting:baseURL forKey:QueryBaseURL];
}

+ (NSString *)baseURL {
    return [LCSettings settingForKey:QueryBaseURL];
}

#pragma mark Header

+ (void)setDefaultHeaderValue:(NSString *)value forKey:(NSString *)key {
    NSMutableDictionary *defaultHeaderValues = [[[self class] defaultHeaderValues] mutableCopy];
    
    if (defaultHeaderValues == nil) {
        defaultHeaderValues = [NSMutableDictionary new];
    }
    
    [defaultHeaderValues setObject:value forKey:key];
    
    [LCSettings setSetting:defaultHeaderValues forKey:QueryDefaultHeaderFieldKey];
}

+ (void)setDefaultHeaderValues:(NSDictionary *)values {
    [LCSettings setSetting:values forKey:QueryDefaultHeaderFieldKey];
}

+ (NSDictionary *)defaultHeaderValues {
    return [LCSettings settingForKey:QueryDefaultHeaderFieldKey];
}

+ (void)cleanDefaultHeader {
    
}

#pragma mark Parameters

+ (void)setDefaultParameter:(NSString *)parameter forKey:(NSString *)key {
    NSMutableDictionary *defaultParameters = [[[self class] defaultParameters] mutableCopy];
    
    if (defaultParameters == nil) {
        defaultParameters = [NSMutableDictionary new];
    }
    
    [defaultParameters setObject:parameter forKey:key];
    
    [LCSettings setSetting:defaultParameters forKey:QueryDefaultParametersKey];
}

+ (void)setDefaultParameters:(NSDictionary *)parameters {
    [LCSettings setSetting:parameters forKey:QueryDefaultParametersKey];
}

+ (NSDictionary *)defaultParameters {
    return [LCSettings settingForKey:QueryDefaultParametersKey];
}

+ (void)enableCerFile:(NSString *)fileName {
    [LCSettings setSetting:fileName forKey:QueryCertFileNameKey];
}

#pragma mark - Instance Method

- (void)sendWithCompletion:(LCResultBlock)completion {
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:[self.class baseURL]]];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    // add acceptableContentType
    NSMutableSet *acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes mutableCopy];
    [acceptableContentTypes addObject:@"application/vnd.api+json"];
    manager.responseSerializer.acceptableContentTypes = acceptableContentTypes;
    
    // security policy
    NSString *baseURLScheme = [NSURL URLWithString:[self.class baseURL]].scheme;
    NSString *cerFileName = [LCSettings settingForKey:QueryCertFileNameKey];
    if (cerFileName != nil && [baseURLScheme isEqualToString:@"https"]) {
        AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
        manager.securityPolicy = policy;
        
        NSString *pathToCert = [[NSBundle mainBundle]pathForResource:cerFileName ofType:@"cer"];
        NSData *localCertificate = [NSData dataWithContentsOfFile:pathToCert];
        manager.securityPolicy.pinnedCertificates = [NSSet setWithObject:localCertificate];
    }
    
    NSString *requestMethod;
    
    switch (self.requestMethod) {
        case LCRequestMethodGET:
            requestMethod = @"GET";
            break;
        case LCRequestMethodPOST:
            requestMethod = @"POST";
            break;
        case LCRequestMethodPUT:
            requestMethod = @"PUT";
            break;
        case LCRequestMethodDELETE:
            requestMethod = @"DELETE";
            break;
            
            
        default:
            if (completion) {
                NSError *error = [NSError errorWithDomain:@"error" code:400 userInfo:@{@"message": @"invalid request method"}];
                completion(@"error", error);
                return;
            }
            break;
    }
    
    // compose request url
    NSMutableURLRequest *request;
    NSString *urlString = self.requestUrl;
    
    // add default parameters
    //    NSDictionary *defaultParameters = [LCQuery defaultParameters];
    //    if (defaultParameters != nil) {
    //        for (NSString *key in defaultParameters.allKeys) {
    //            NSString *parameterValue = [defaultParameters[key] description];
    //
    //            // Skip, if the key already in the current parameters.
    //            if (self.parameters[key] == nil) {
    //                [self.parameters setObject:parameterValue forKey:key];
    //            }
    //        }
    //    }
    
    if (!self.appendData && [urlString rangeOfString:@"tapcrowd.com"].location == NSNotFound) {
        request = [manager.requestSerializer requestWithMethod:requestMethod
                                                     URLString:urlString
                                                    parameters:self.parameters
                                                         error:nil];
    } else {
        request = [manager.requestSerializer multipartFormRequestWithMethod:requestMethod
                                                                  URLString:urlString
                                                                 parameters:self.parameters
                                                  constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                      if (self.appendData) {
                                                          [formData appendPartWithFileData:self.appendData name:@"file" fileName:@"file.png" mimeType:@"image/png"];
                                                      }
                                                  }
                                                                      error:nil];
    }
    
    NSLog(@"[%@] %@", requestMethod, urlString);
    NSLog(@"\nparameters: %@", self.parameters);
    if (request.HTTPBody) {
        NSDictionary *body = [NSJSONSerialization JSONObjectWithData:request.HTTPBody
                                                             options:0
                                                               error:nil];
        NSLog(@"\request body: %@", body);
    }
    
    // add header
    // installation id
    if ([urlString rangeOfString:@"tapcrowd.com"].location == NSNotFound) {
        NSDictionary *defaultHeader = [LCQuery defaultHeaderValues];
        NSLog(@"defaultHeader: %@", defaultHeader);
        if (defaultHeader != nil) {
            for (NSString *key in defaultHeader.allKeys) {
                NSString *value = [defaultHeader[key] description];
                
                // Skip, if the key already in the current parameters.
                if (self.header[key] == nil) {
                    [self.header setObject:value forKey:key];
                }
            }
        }
        
        if (self.header.allKeys.count > 0) {
            [self handleHeader:self.header forRequest:request];
        }
    }
    
    NSURLSessionDataTask *task = [manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            // failed
            completion(responseObject, error);
        } else {
            // succeed
            completion(responseObject, nil);
        }
    }];
    
    [request setTimeoutInterval:self.timeoutInterval];
    
    [task resume];
}

- (void)handleHeader:(NSDictionary *)header forRequest:(NSMutableURLRequest *)request {
    if (header != nil && [header isKindOfClass:[NSDictionary class]]) {
        NSArray *allKeys = header.allKeys;
        for (NSString *key in allKeys) {
            [request addValue:[header objectForKey:key] forHTTPHeaderField:key];
        }
    }
}

@end
