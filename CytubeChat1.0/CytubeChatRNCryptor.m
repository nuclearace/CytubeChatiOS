//
//  CytubeChatRNCryptor.m
//  CytubeChat
//
//  Created by Erik Little on 12/13/14.
//

#import "CytubeChatRNCryptorHeader.h"

@implementation CytubeChatRNCryptor

+ (NSData *)encryptData:(NSData * __nullable)data password:(NSString * __nonnull)password error:(NSError ** __nullable)error {
    
    return [self encryptData:data withSettings:kRNCryptorAES256Settings password:password error:error];
}

@end