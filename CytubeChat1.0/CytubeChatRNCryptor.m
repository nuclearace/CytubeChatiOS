//
//  CytubeChatRNCryptor.m
//  CytubeChat
//
//  Created by Erik Little on 12/13/14.
//

#import "CytubeChatRNCryptorHeader.h"

@implementation CytubeChatRNCryptor

+ (NSData *)encryptData:(NSData *)data password:(NSString *)password error:(NSError **)error {
    
    return [self encryptData:data withSettings:kRNCryptorAES256Settings password:password error:error];
}

@end