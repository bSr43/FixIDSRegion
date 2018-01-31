//
//  main.m
//  FixIDSRegion
//
//  Created by Vincent Bénony on 25/01/2018.
//  Copyright © 2018 Vincent Bénony. All rights reserved.
//

#import <Foundation/Foundation.h>


int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc != 3) {
            fprintf(stderr, "Usage: FixIDSRegion country phone_pattern\n");
            fprintf(stderr, "Examples:\n");
            fprintf(stderr, "   FixIDSRegion R:US +10000000000\n");
            fprintf(stderr, "   FixIDSRegion R:FR +330000000000\n");
            exit(1);
        }

        CFStringRef countryStr = CFStringCreateWithCString(kCFAllocatorDefault, argv[1], kCFStringEncodingASCII);
        CFStringRef phoneStr = CFStringCreateWithCString(kCFAllocatorDefault, argv[2], kCFStringEncodingASCII);

        if (countryStr == NULL) {
            fprintf(stderr, "Cannot create country string.\n");
            exit(1);
        }
        if (phoneStr == NULL) {
            fprintf(stderr, "Cannot create phone string.\n");
            exit(1);
        }

        CFMutableDictionaryRef getQuery = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                                0,
                                                                NULL,
                                                                NULL);
        
        CFDictionaryAddValue(getQuery, kSecClass, kSecClassGenericPassword);
        CFDictionaryAddValue(getQuery, kSecAttrAccess, CFSTR("registrationV1"));
        CFDictionaryAddValue(getQuery, kSecAttrService, CFSTR("com.apple.facetime"));
        CFDictionaryAddValue(getQuery, kSecReturnData, kCFBooleanTrue);

        CFTypeRef result;
        OSStatus status = SecItemCopyMatching((CFDictionaryRef) getQuery, &result);
        if (status == noErr) {
            if (CFGetTypeID(result) != CFDataGetTypeID()) {
                fprintf(stderr, "Expecting data, got something else, abort...\n");
                exit(1);
            }

            CFDataRef data = (CFDataRef) result;

            CFErrorRef err;
            CFPropertyListRef plist = CFPropertyListCreateWithData(kCFAllocatorDefault, data, 0, NULL, &err);
            if (plist == NULL) {
                fprintf(stderr, "Cannot create plist from data, abort...\n");
                exit(1);
            }

            if (CFGetTypeID(plist) != CFDictionaryGetTypeID()) {
                fprintf(stderr, "Expecting dictionary, got something else, abort...\n");
                exit(1);
            }

            CFArrayRef items = CFDictionaryGetValue((CFDictionaryRef) plist, CFSTR("data"));
            CFMutableArrayRef mutItems = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);

            for (CFIndex i=0; i<CFArrayGetCount(items); i++) {
                CFDictionaryRef item = CFArrayGetValueAtIndex(items, i);
                CFMutableDictionaryRef mutItem = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, item);

                CFDictionarySetValue(mutItem, CFSTR("region-id"), countryStr);
                CFDictionarySetValue(mutItem, CFSTR("region-base-phone-number"), phoneStr);

                CFArrayAppendValue(mutItems, mutItem);
            }

            CFMutableDictionaryRef mutPlist = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, (CFDictionaryRef) plist);
            CFDictionarySetValue(mutPlist, CFSTR("data"), mutItems);


            CFDataRef finalData = CFPropertyListCreateData(kCFAllocatorDefault, (CFPropertyListRef) mutPlist, kCFPropertyListBinaryFormat_v1_0, 0, &err);

            CFMutableDictionaryRef updateQuery = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
            CFDictionaryAddValue(updateQuery, kSecValueData, finalData);

            if (SecItemUpdate(getQuery, updateQuery) != errSecSuccess) {
                fprintf(stderr, "Failed to update the keychain.\n");
            }
        }
    }

    puts("Done");

    return 0;
}
