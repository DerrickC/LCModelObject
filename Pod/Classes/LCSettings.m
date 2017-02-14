//
//  LCSettings.m
//  Loopd
//
//  Created by Derrick Chao on 2016/12/19.
//  Copyright © 2016年 Loopd Inc. All rights reserved.
//

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
