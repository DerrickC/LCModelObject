// Created by Derrick Chao on 2016/12/19.
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


#import "LCSettings.h"

@implementation LCSettings

+ (void)setSetting:(id)object forKey:(NSString *)key {
    NSMutableDictionary *dict = [[self class] loadSettingData];
    if (dict == nil) {
        dict = [NSMutableDictionary new];
    }
    
    [dict setObject:object forKey:key];
    
    [[self class] saveSettingDataToPlistWithDicionary:dict];
}

+ (id)settingForKey:(NSString *)key {
    NSMutableDictionary *dict = [[self class] loadSettingData];
    if (dict != nil) {
        return dict[key];
    }
    
    
    return nil;
}

+ (void)cleanForKey:(NSString *)key {
    NSMutableDictionary *dict = [[self class] loadSettingData];
    if (dict == nil) {
        dict = [NSMutableDictionary new];
    }
    
    [dict removeObjectForKey:key];
    
    [[self class] saveSettingDataToPlistWithDicionary:dict];
}

+ (NSMutableDictionary *)loadSettingData {
    NSURL *docUrl = DOC_PATH;
    // get documents path
    NSString *documentsPath = docUrl.path;
    // get the path to our Data/plist file
    NSString *plistPath =
    [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", SettingsPlistFileName]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        plistPath = [[NSBundle mainBundle] pathForResource:SettingsPlistFileName ofType:@"plist"];
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    
    return dict;
}

+ (void)saveSettingDataToPlistWithDicionary:(NSDictionary *)dict {
    NSURL *docUrl = DOC_PATH;
    
    // get documents path
    NSString *documentsPath = docUrl.path;
    // get the path to our Data/plist file
    NSString *plistPath =
    [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", SettingsPlistFileName]];
    
    [dict writeToFile:plistPath atomically:YES];
}

+ (BOOL)deletePlistFile {
    NSURL *docUrl = DOC_PATH;
    // get documents path
    NSString *documentsPath = docUrl.path;
    // get the path to our Data/plist file
    NSString *plistPath =
    [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", SettingsPlistFileName]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        NSError *error;
        return [[NSFileManager defaultManager] removeItemAtPath:plistPath error:&error];
    }
    
    return NO;
}

@end
