//
//  SPGooglePlacesAutocompletePlace.m
//  SPGooglePlacesAutocomplete
//
//  Created by Stephen Poletto on 7/17/12.
//  Copyright (c) 2012 Stephen Poletto. All rights reserved.
//

#import "SPGooglePlacesAutocompletePlace.h"
#import "SPGooglePlacesPlaceDetailQuery.h"
#import "SPGooglePlacemark.h"

@interface SPGooglePlacesAutocompletePlace()
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *reference;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSArray *types;
@end

@implementation SPGooglePlacesAutocompletePlace

+ (SPGooglePlacesAutocompletePlace *)placeFromDictionary:(NSDictionary *)placeDictionary apiKey:(NSString *)apiKey
{
    SPGooglePlacesAutocompletePlace *place = [[self alloc] init];
    place.name = placeDictionary[@"description"];
    place.reference = placeDictionary[@"reference"];
    place.identifier = placeDictionary[@"id"];
    place.types = SPPlaceTypeFromDictionary(placeDictionary);
    place.key = apiKey;
    return place;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Name: %@, Reference: %@, Identifier: %@, Types: %@",
            self.name, self.reference, self.identifier, SPPlaceTypeStringForPlaceTypes(self.types)];
}

- (CLGeocoder *)geocoder {
    if (!geocoder) {
        geocoder = [[CLGeocoder alloc] init];
    }
    return geocoder;
}

- (void)fetchPlaceDetails:(SPGooglePlacesPlacemarkResultBlock)block {
    SPGooglePlacesPlaceDetailQuery *query = [[SPGooglePlacesPlaceDetailQuery alloc] initWithApiKey:self.key];
    query.reference                       = self.reference;
    
    [query fetchPlaceDetail:^(NSDictionary *placeDictionary, NSError *error) {
        if (error) {
            block(nil, error);
        }
        else {
            CLLocationCoordinate2D coordinates = CLLocationCoordinate2DMake(
                                                                            [placeDictionary[@"geometry"][@"location"][@"lat"] doubleValue],
                                                                            [placeDictionary[@"geometry"][@"location"][@"lng"] doubleValue]
                                                                            );
            CLLocation *location         = [[CLLocation alloc] initWithLatitude:coordinates.latitude longitude:coordinates.longitude];
            NSArray *components          = placeDictionary[@"address_components"];
            NSString *locality           = nil;
            SPGooglePlacemark *placemark = nil;
            
            for (NSDictionary *component in components) {
                NSArray *types = component[@"types"];
                
                for (NSString *type in types) {
                    if ([type isEqualToString:@"locality"]) {
                        locality = component[@"short_name"];
                        break;
                    }
                }
                
                if (locality) {
                    break;
                }
            }
            
            if (location && locality) {
                placemark = [[SPGooglePlacemark alloc] initWithLocality:locality location:location];
            }
            
            block(placemark, nil);
        }
    }];
}

- (void)resolveToPlacemark:(SPGooglePlacesPlacemarkResultBlock)block {
    [self fetchPlaceDetails:block];
}


@end
