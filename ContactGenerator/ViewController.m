//
//  ViewController.m
//  ContactGenerator
//
//  Created by Seung-Hwan Lee on 2016. 1. 20..
//  Copyright © 2016년 LinePlus. All rights reserved.
//

#import "ViewController.h"
@import AddressBook;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tapGenerateButton:(id)sender {
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied ||
        ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted){
        //1
        NSLog(@"Denied");
        UIAlertView *cantAddContactAlert = [[UIAlertView alloc] initWithTitle: @"Cannot Add Contact" message: @"You must give the app permission to add the contact first." delegate:nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
        [cantAddContactAlert show];
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized){
        //2
        NSLog(@"Authorized");
        [self generateSimulatorContacts];
        [self generateDeviceContacts];
        NSLog(@"\nCompleted!");
    } else{ //ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined
        //3
        NSLog(@"Not determined");
        ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!granted){
                    //4
                    UIAlertView *cantAddContactAlert = [[UIAlertView alloc] initWithTitle: @"Cannot Add Contact" message: @"You must give the app permission to add the contact first." delegate:nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
                    [cantAddContactAlert show];
                    return;
                }
                //5
                [self generateSimulatorContacts];
                [self generateDeviceContacts];
                NSLog(@"\nCompleted!");
            });
        });
    }
}

- (IBAction)tapCleanButton:(id)sender
{
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied ||
        ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted){
        //1
        NSLog(@"Denied");
        UIAlertView *cantAddContactAlert = [[UIAlertView alloc] initWithTitle: @"Cannot Clean Contact"
                                                                      message: @"You must give the app permission to clean the contact first."
                                                                     delegate:nil
                                                            cancelButtonTitle: @"OK"
                                                            otherButtonTitles: nil];
        [cantAddContactAlert show];
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized){
        //2
        NSLog(@"Authorized");
        [self cleanAllContacts];
        NSLog(@"\nCompleted!");
    } else{ //ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined
        //3
        NSLog(@"Not determined");
        ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!granted){
                    //4
                    UIAlertView *cantAddContactAlert = [[UIAlertView alloc] initWithTitle: @"Cannot Clean Contact"
                                                                                  message: @"You must give the app permission to clean the contact first."
                                                                                 delegate:nil
                                                                        cancelButtonTitle: @"OK"
                                                                        otherButtonTitles: nil];
                    [cantAddContactAlert show];
                    return;
                }
                //5
                [self cleanAllContacts];
                NSLog(@"\nCompleted!");
            });
        });
    }
}

- (void)cleanAllContacts
{
    ABAddressBookRef addressBookRef = ABAddressBookCreate( );
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople( addressBookRef );
    CFIndex nPeople = ABAddressBookGetPersonCount( addressBookRef );

    for ( int i = 0; i < nPeople; i++ )
    {
        ABRecordRef ref = CFArrayGetValueAtIndex( allPeople, i );

        CFErrorRef *error = nil;
        if (!ABAddressBookRemoveRecord(addressBookRef, ref, error)) {
            NSLog(@"error %@", *error);
            break;
        }
    }

    ABAddressBookSave(addressBookRef, nil);
}

- (void)generateSimulatorContacts
{
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, nil);
    
    NSDictionary<NSString*,NSString*> *countryPrefixDic = @{@"KR" : @"010",
                                                            @"JP" : @"080"};
    [countryPrefixDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull countryCode, NSString * _Nonnull countryTel, BOOL * _Nonnull stop) {
        
        NSDictionary<NSString*,NSString*> *contactDic = @{@"4s"  : @"4800",
                                                          @"5"   : @"5000",
                                                          @"5s"  : @"5800",
                                                          @"6"   : @"6000",
                                                          @"6+"  : @"6004",
                                                          @"6s"  : @"6800",
                                                          @"6s+" : @"6804",
                                                          @"7"   : @"7000",
                                                          @"7+"  : @"7004",
                                                          @"8"   : @"8000",
                                                          @"8+"  : @"8004",
                                                          };
        [[[contactDic allKeys] sortedArrayUsingSelector:@selector(compare:)] enumerateObjectsUsingBlock:^(NSString * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSString * telPrefix = contactDic[model];
            
            for (NSInteger tel2 = 81 ; tel2 < 110 ; tel2++) {
                
                NSString *contactName = [NSString stringWithFormat:@"%@ sim %@ %ld.%ld", countryCode, model, (long)(tel2/10), (long)(tel2%10)];
                NSString *telNumber = [NSString stringWithFormat:@"%@%@%04ld", countryTel, telPrefix, (long)tel2];
                
                ABRecordRef pet = ABPersonCreate();
                ABRecordSetValue(pet, kABPersonLastNameProperty, (__bridge CFStringRef)contactName, nil);
                
                ABMutableMultiValueRef phoneNumbers = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                ABMultiValueAddValueAndLabel(phoneNumbers, (__bridge CFStringRef)telNumber, kABPersonPhoneMainLabel, NULL);
                ABRecordSetValue(pet, kABPersonPhoneProperty, phoneNumbers, nil);
                
                ABAddressBookAddRecord(addressBookRef, pet, nil);
                
                NSLog(@"added %@ %@", contactName, telNumber);
            }
        }];
    }];
    
    ABAddressBookSave(addressBookRef, nil);
}

- (void)generateDeviceContacts
{
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, nil);
    
    NSDictionary<NSString*,NSString*> *countryPrefixDic = @{@"KR" : @"010",
                                                            @"JP" : @"080"};
    [countryPrefixDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull countryCode, NSString * _Nonnull countryTel, BOOL * _Nonnull stop) {
        
        NSDictionary<NSString*,NSString*> *contactDic = @{@"iPhone 5ss"  : @"53786146",
                                                          @"iPhone 5ss b": @"53786148",
                                                          @"iPhone 6+"   : @"21442162",
                                                          @"iPhone 6+ b" : @"21442168",
                                                          @"iPhone 7"    : @"32715507",
                                                          @"iPhone 7 b"  : @"32715508"};
        [[[contactDic allKeys] sortedArrayUsingSelector:@selector(compare:)] enumerateObjectsUsingBlock:^(NSString * _Nonnull contactName, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSString * telNumber = contactDic[contactName];
            
            contactName = [NSString stringWithFormat:@"%@ %@", countryCode, contactName];
            telNumber = [NSString stringWithFormat:@"%@%@", countryTel, telNumber];
            
            ABRecordRef pet = ABPersonCreate();
            ABRecordSetValue(pet, kABPersonLastNameProperty, (__bridge CFStringRef)contactName, nil);
            
            ABMutableMultiValueRef phoneNumbers = ABMultiValueCreateMutable(kABMultiStringPropertyType);
            ABMultiValueAddValueAndLabel(phoneNumbers, (__bridge CFStringRef)telNumber, kABPersonPhoneMainLabel, NULL);
            ABRecordSetValue(pet, kABPersonPhoneProperty, phoneNumbers, nil);
            
            ABAddressBookAddRecord(addressBookRef, pet, nil);
            
            NSLog(@"added %@ %@", contactName, telNumber);
        }];
    }];
    
    ABAddressBookSave(addressBookRef, nil);
}

@end
