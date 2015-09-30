/*
 * Copyright 2010 Stephen Darlington
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "UIActionSheetAutoDismiss.h"

@implementation UIActionSheetAutoDismiss

- (id)init {
    if (self = [super init]) {
        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        if ([[UIDevice currentDevice].systemVersion intValue] >= 4) {
            // Close ourseleves when the app exits the foreground
            [nc addObserver:self
                   selector:@selector(cancelActionSheet:)
                       name:UIApplicationDidEnterBackgroundNotification
                     object:nil];
        }
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            // Close ourselves when another UIActionSheet opens
            [nc postNotificationName:@"UIActionSheetAutoDismissLaunched" object:self];
            [nc addObserver:self
                   selector:@selector(cancelActionSheet:)
                       name:@"UIActionSheetAutoDismissLaunched"
                     object:nil];
        }
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)cancelActionSheet:(id)sender {
    [self dismissWithClickedButtonIndex:[self cancelButtonIndex] animated:NO];
}

@end