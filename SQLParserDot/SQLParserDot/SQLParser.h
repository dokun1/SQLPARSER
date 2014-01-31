//
//  SQLParser.h
//  SQLParserDot
//
//  Copyright (c) 2014 DMOS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SQLParser : NSObject

+(NSString*)getDotOutputForSQLSchema:(NSDictionary*)schema;
+(NSDictionary*)getSQLSchemaValuesForFilepath:(NSString*)filePath;
+(NSDictionary*)getSQLSchemaValues; // this uses the default mondial-schema.sql file

@end
