//
//  KSFTPParserTests.m
//  KSFTPParserTests
//
//  Created by Sam Deane on 16/05/2013.
//  Copyright (c) 2013 Karelia. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "KSFTPParser.h"

@interface KSFTPParserTests : SenTestCase

@end

@implementation KSFTPParserTests

- (BOOL)checkItems:(NSArray*)items
{
    NSArray* names = @[@"directory", @"file1.txt", @"file2.txt"];
    KSFTPEntryType types[] = { KSFTPDirectoryEntry, KSFTPFileEntry, KSFTPFileEntry };
    NSCalendar* calendar = [NSCalendar currentCalendar];
    calendar.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];

    NSUInteger count = [items count];
    BOOL ok = count == 3;
    if (ok)
    {
        for (NSUInteger n = 0; ok && (n < count); ++n)
        {
            NSDictionary* item = items[n];
            KSFTPEntryType type = (KSFTPEntryType) [item[@"type"] integerValue];
            ok = type == types[n];
            if (!ok)
            {
                NSLog(@"expected type %ld, got %ld", types[n], type);
            }

            if (ok)
            {
                NSString* name = item[@"name"];
                ok = [name isEqualToString:names[n]];
                if (!ok)
                {
                    NSLog(@"expected name %@ got %@", names[n], name);
                }
            }

            if (ok)
            {
                NSDate* time = item[@"modified"];
                NSUInteger flags = (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit);
                NSDateComponents* components = [calendar components:flags fromDate:time];
                ok = ((components.year == 1969) || (components.year == 2069)) // 2-digit dates are interpreted as 2000 if < 80, 1900 if >= 80
                    && (components.month == 11)
                    && (components.day == 12);
                if (!ok)
                {
                    NSLog(@"unexpected time %@", time);
                }
            }
        }
    }
    else
    {
        NSLog(@"expected 3 results, got %ld", count);
    }

    return ok;
}

- (void)testJunkInput
{
    NSString* input = @"Blah\nBlah\nBlah";
    NSArray* items = [KSFTPParser parseString:input includingExtraEntries:YES];

    STAssertEquals([items count], 3UL, @"expected 3 results, got %ld", [items count]);
    for (NSDictionary* item in items)
    {
        KSFTPEntryType type = (KSFTPEntryType) [item[@"type"] integerValue];
        STAssertEquals(type, KSFTPMiscEntry, @"expected type 3, got %ld", type);
    }
    
}

- (void)testWindows
{
    NSString* input =
        @"11-12-69  01:02PM      <DIR>          directory\r\n"
         "11-12-69  03:04AM                7352 file1.txt\r\n"
         "11-12-69  05:06AM                5246 file2.txt\r\n";

    NSArray* items = [KSFTPParser parseString:input includingExtraEntries:NO];
    STAssertTrue([self checkItems:items], @"unexpected output: %@", items);
}

- (void)testUnix
{
    NSString* input = @"total 1\r\n"
    "drw-------   1 user  staff     3 Nov  12  1969 directory\r\n"
    "-rw-------   1 user  staff     3 Nov  12  1969 file1.txt\r\n"
    "-rw-------   1 user  staff     3 Nov  12  1969 file2.txt\r\n\r\n";

    NSArray* items = [KSFTPParser parseString:input includingExtraEntries:NO];
    STAssertTrue([self checkItems:items], @"unexpected output: %@", items);
}

@end
