//
//  LCSettings.h
//  Loopd
//
//  Created by Derrick Chao on 2016/12/19.
//  Copyright © 2016 Loopd Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DOC_PATH [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
#define SettingsPlistFileName                           @"LCModelObjectSettingsPlistFileName"
#define DateTransTypeUserDefaultKey                     @"DateTransTypeUserDefaultKey"
#define DateFormatUserDefaultKey                        @"DateFormatUserDefaultKey"
#define ManyToManyTableNamesUserDefaultKey              @"ManyToManyTableNamesUserDefaultKey"

@interface LCSettings : NSObject

+ (void)setSetting:(id)object forKey:(NSString *)key;
+ (id)settingForKey:(NSString *)key;

@end
