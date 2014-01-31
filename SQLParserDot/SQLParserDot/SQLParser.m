//
//  SQLParser.m
//  SQLParserDot
//
//  Copyright (c) 2014 DMOS. All rights reserved.
//

#import "SQLParser.h"
#import "NSString+APString.h"

@implementation SQLParser

+(NSString*)getDotOutputForSQLSchema:(NSDictionary*)schema {
    NSMutableString *dotOutput = [NSMutableString string];
    [dotOutput appendString:@"digraph {\nrankdir=BT\n\n"];
    [dotOutput appendString:@"node [shape=\"box\" style=\"filled\" color=\"#0000FF\" fillcolor=\"#FFCCCC\" fontname=\"Courier\" ]\n\n"];
    
    for (NSString *tableName in [schema allKeys]) {
        NSString *updatedTableName = [tableName uppercaseString];
        [dotOutput appendString:updatedTableName];
        [dotOutput appendString:@"\n"];
    }
    [dotOutput appendString:@"\nnode [shape=\"oval\" style=\"filled\" color=\"#0000FF\" fillcolor=\"#DCF0F7\" fontname=\"Courier\"]\n"];
    
    for (NSString *tableName in [schema allKeys]) {
        NSDictionary *tableDict = schema[tableName];
        for (NSString *attName in [tableDict allKeys]) {
            NSDictionary *attDict = tableDict[attName];
            NSNumber *primary = attDict[@"isPrimaryKey"];
            BOOL isPrimary = [primary boolValue];
            NSString *append = [NSString string];
            if (isPrimary) {
                append = [NSString stringWithFormat:@"%@_%@[label=\"%@\" fontname=\"Courier-Bold\"]", tableName, attDict[@"attributeName"], attDict[@"attributeName"]];
            }else{
                append = [NSString stringWithFormat:@"%@_%@[label=\"%@\"]", tableName,     attDict[@"attributeName"], attDict[@"attributeName"]];
            }
            [dotOutput appendString:append];
            [dotOutput appendString:@"\n"];
        }
    }
    
    [dotOutput appendString:@"\n"];
    [dotOutput appendString:@"edge [color=\"#00AA00\" dir=none]\n"];
    
    for (NSString *tableName in [schema allKeys]) {
        NSString *updatedTableName = [tableName uppercaseString];
        [dotOutput appendString:updatedTableName];
        [dotOutput appendString:@" -> {"];
        NSDictionary *tableDict = schema[tableName];
        for (int i = 0; i < [[tableDict allKeys] count]; i++) {
            NSString *attName = [tableDict allKeys][i];
            NSDictionary *attDict = tableDict[attName];
            NSString *append = [NSString stringWithFormat:@"%@_%@", tableName, attDict[@"attributeName"]];
            [dotOutput appendString:append];
            if (i != [[tableDict allKeys] count] - 1){
                [dotOutput appendString:@" "];
            }
        }
        [dotOutput appendString:@"}\n"];
    }
    [dotOutput appendString:@"\n"];
    [dotOutput appendString:@"edge [color=red dir=forward style=dashed label=\"FK\" fontname=\"Verdana\" fontcolor=red fontsize=10]\n\n"];
    
    for (NSString *tableName in [schema allKeys]) {
        NSDictionary *tableDict = schema[tableName];
        for (int i = 0; i < [[tableDict allKeys] count]; i++) {
            NSString *attName = [tableDict allKeys][i];
            NSDictionary *attDict = tableDict[attName];
            NSDictionary *foreignKey = attDict[@"foreignKey"];
            if (foreignKey != nil) {
                NSString *foreignTableName = [NSString string];
                NSString *foreignAttName = [NSString string];
                for (NSString *key in [foreignKey allKeys]) {
                    if ([key isEqualToString:@"TABLE"]) {
                        foreignTableName = foreignKey[key];
                    }else{
                        foreignAttName = foreignKey[key];
                    }
                }
                NSString *append = [NSString string];
                if ([foreignAttName isEqualToString:@"TABLE"]) {
                    NSString *caseForeignTableName = [foreignTableName uppercaseString];
                    append = [NSString stringWithFormat:@"%@_%@ -> %@\n", tableName, attDict[@"attributeName"], caseForeignTableName];
                }else{
                    append = [NSString stringWithFormat:@"%@_%@ -> %@_%@\n", tableName, attDict[@"attributeName"], foreignTableName, foreignAttName];
                }
                
                [dotOutput appendString:append];
            }
        }
    }
    [dotOutput appendString:@"\n\n}"];
    return dotOutput;
}

+(NSDictionary*)getSQLSchemaValuesForFilepath:(NSString*)filePath{
    
    NSString *nsFilePath = [[NSBundle mainBundle] pathForResource:filePath ofType:@"sql"];
    NSString *theString = [NSString stringWithContentsOfFile:nsFilePath encoding:NSUTF8StringEncoding error:nil];
    
    NSMutableArray *arrayOfTables = [[theString componentsSeparatedByString:@";"] mutableCopy];
    [arrayOfTables removeLastObject];
    
    NSMutableDictionary *finalDict = [NSMutableDictionary dictionary];
    
    for (NSString *table in arrayOfTables) {
        NSMutableDictionary *tableDict = [NSMutableDictionary dictionary];
        NSMutableString *mutableTableCopy = [[table stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy];
        if ([mutableTableCopy containsString:@"CREATE TABLE"]) {
            mutableTableCopy = [[mutableTableCopy stringByReplacingOccurrencesOfString:@"CREATE TABLE " withString:@""] mutableCopy];
            mutableTableCopy = [[mutableTableCopy stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy];
            NSString *tableName = [mutableTableCopy componentsSeparatedByString:@"\n"][0];
            tableName = [tableName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [tableDict setObject:tableName forKey:@"tableName"];
            NSRange nameRange = [mutableTableCopy rangeOfString:tableName];
            if (NSNotFound != nameRange.location) {
                mutableTableCopy = [[mutableTableCopy stringByReplacingCharactersInRange:nameRange withString:@" "]mutableCopy];
            }
            NSRange parentRange = [mutableTableCopy rangeOfString:@"("];
            if (NSNotFound != parentRange.location) {
                mutableTableCopy = [[mutableTableCopy stringByReplacingCharactersInRange:parentRange withString:@""] mutableCopy];
            }
            mutableTableCopy = [[mutableTableCopy substringToIndex:[mutableTableCopy length] - 1] mutableCopy];
            NSArray *attArray = [mutableTableCopy componentsSeparatedByString:@","];
            NSMutableDictionary *attTableDict = [NSMutableDictionary dictionary];
            for (int i = 0; i < [attArray count]; i++) {
                NSString *attribute = attArray[i];
                NSMutableDictionary *attDict = [NSMutableDictionary dictionary];
                NSMutableString *mutableAtt = [[attribute stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy];
                NSString *attName = [mutableAtt componentsSeparatedByString:@" "][0];
                NSRange endRange = [attName rangeOfString:@")"];
                if (NSNotFound != endRange.location) {
                    attName = [attName stringByReplacingCharactersInRange:endRange withString:@""];
                }
                attName = [attName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSString *lookup = [NSString stringWithFormat:@"att=%@", attName];
                NSDictionary *checkDict = attTableDict[lookup];
                if (checkDict) {
                    continue;
                }
                if (![attName isEqualToString:@"CONSTRAINT"]) {
                    [attDict setObject:attName forKey:@"attributeName"];
                    BOOL isPrimary = [mutableAtt containsString:@"PRIMARY KEY"];
                    [attDict setObject:[NSNumber numberWithBool:isPrimary] forKey:@"isPrimaryKey"];
                    if ([attribute containsString:@"REFERENCES"]) {
                        NSString *foreignKeys = [attribute componentsSeparatedByString:@"REFERENCES"][1];
                        foreignKeys = [foreignKeys stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        NSString *foreignTable = [foreignKeys componentsSeparatedByString:@" "][0];
                        NSDictionary *foreignKey = @{attName : @"TABLE",
                                                     @"TABLE": foreignTable};
                        [attDict setObject:foreignKey forKey:@"foreignKey"];
                    }
                }else{
                    NSMutableString *constraintString = [NSMutableString string];
                    int finalIndex = 0;
                    for (int j = i ; j < [attArray count]; j++) {
                        NSString *checkString = attArray[j];
                        [constraintString appendString:checkString];
                        finalIndex = j;
                        BOOL shouldBreak = ([checkString containsString:@")"] && ![checkString containsString:@"REFERENCES"]);
                        if (shouldBreak) {
                            break;
                        }else{
                            [constraintString appendString:@","];
                        }
                    }
                    if ([constraintString containsString:@"PRIMARY"]) {
                        NSRange start = [constraintString rangeOfString:@"("];
                        NSRange end = [constraintString rangeOfString:@")"];
                        NSString *string = [constraintString substringWithRange:NSMakeRange(start.location + 1, (end.location - start.location) - 1)];
                        NSArray *keys = [string componentsSeparatedByString:@","];
                        for (NSString *key in keys) {
                            NSString *neatKey = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            NSString *lookupString = [NSString stringWithFormat:@"att=%@", neatKey];
                            NSMutableDictionary *changeKeyDict = attTableDict[lookupString];
                            [changeKeyDict setObject:[NSNumber numberWithBool:YES] forKey:@"isPrimaryKey"];
                            [attTableDict setObject:changeKeyDict forKey:lookupString];
                        }
                    }
                    if ([constraintString containsString:@"FOREIGN"]) {
                        NSArray *foreignKeys = [constraintString componentsSeparatedByString:@"REFERENCES"];
                        NSString *theseKeys = foreignKeys[0];
                        NSRange start = [theseKeys rangeOfString:@"("];
                        NSRange end = [theseKeys rangeOfString:@")"];
                        NSString *string = [theseKeys substringWithRange:NSMakeRange(start.location + 1, (end.location - start.location) - 1)];
                        NSArray *theseKeysArray = [string componentsSeparatedByString:@","];
                        NSString *thoseKeys = foreignKeys[1];
                        start = [thoseKeys rangeOfString:@"("];
                        NSString *foreignTable = [thoseKeys substringWithRange:NSMakeRange(0, start.location)];
                        foreignTable = [foreignTable stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        end = [thoseKeys rangeOfString:@")"];
                        string = [thoseKeys substringWithRange:NSMakeRange(start.location + 1, (end.location - start.location) - 1)];
                        NSArray *thoseKeysArray = [string componentsSeparatedByString:@","];
                        for (int a = 0; a < [theseKeysArray count]; a++) {
                            NSString *thisKey = theseKeysArray[a];
                            NSString *thatKey = thoseKeysArray[a];
                            thisKey = [thisKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            thatKey = [thatKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            NSString *lookupString = [NSString stringWithFormat:@"att=%@", thisKey];
                            NSMutableDictionary *changeKeyDict = attTableDict[lookupString];
                            NSDictionary *foreignKey = @{thisKey : thatKey,
                                                         @"TABLE": foreignTable};
                            [changeKeyDict setObject:foreignKey forKey:@"foreignKey"];
                            [attTableDict setObject:changeKeyDict forKey:lookupString];
                        }
                    }
                }
                if ([attDict objectForKey:@"attributeName"] != nil) {
                    [attTableDict setObject:attDict forKey:[NSString stringWithFormat:@"att=%@", [attDict objectForKey:@"attributeName"]]];
                }
                
            }
            [finalDict setObject:attTableDict forKey:tableName];
        }else{
            if ([mutableTableCopy containsString:@"CREATE"]) {
                continue;
            }
            mutableTableCopy = [[mutableTableCopy stringByReplacingOccurrencesOfString:@"ALTER TABLE " withString:@""] mutableCopy];
            mutableTableCopy = [[mutableTableCopy stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy];
            NSArray *breakupArray = [mutableTableCopy componentsSeparatedByString:@"\n"];
            NSString *tableName = breakupArray[0];
            
            NSMutableDictionary *lookupDict = finalDict[tableName];
            
            NSMutableString *constraintString = [NSMutableString string];
            int finalIndex = 0;
            for (int j = 1 ; j < [breakupArray count]; j++) {
                NSString *checkString = breakupArray[j];
                [constraintString appendString:checkString];
                finalIndex = j;
                BOOL shouldBreak = ([checkString containsString:@")"] && ![checkString containsString:@"("]);
                if (shouldBreak) {
                    break;
                }else{
                    [constraintString appendString:@","];
                }
            }
            if ([constraintString containsString:@"FOREIGN"]) {
                NSArray *foreignKeys = [constraintString componentsSeparatedByString:@"REFERENCES"];
                NSString *theseKeys = foreignKeys[0];
                NSRange start = [theseKeys rangeOfString:@"("];
                NSRange end = [theseKeys rangeOfString:@")"];
                NSString *string = [theseKeys substringWithRange:NSMakeRange(start.location + 1, (end.location - start.location) - 1)];
                NSArray *theseKeysArray = [string componentsSeparatedByString:@","];
                NSString *thoseKeys = foreignKeys[1];
                start = [thoseKeys rangeOfString:@"("];
                NSString *foreignTable = [thoseKeys substringWithRange:NSMakeRange(0, start.location)];
                foreignTable = [foreignTable stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                end = [thoseKeys rangeOfString:@")"];
                string = [thoseKeys substringWithRange:NSMakeRange(start.location + 1, (end.location - start.location) - 1)];
                NSArray *thoseKeysArray = [string componentsSeparatedByString:@","];
                for (int a = 0; a < [theseKeysArray count]; a++) {
                    NSString *thisKey = theseKeysArray[a];
                    NSString *thatKey = thoseKeysArray[a];
                    thisKey = [thisKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    thatKey = [thatKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    NSString *lookupString = [NSString stringWithFormat:@"att=%@", thisKey];
                    NSMutableDictionary *changeKeyDict = lookupDict[lookupString];
                    NSDictionary *foreignKey = @{thisKey : thatKey,
                                                 @"TABLE": foreignTable};
                    [changeKeyDict setObject:foreignKey forKey:@"foreignKey"];
                    [lookupDict setObject:changeKeyDict forKey:lookupString];
                }
            }
            [finalDict setObject:lookupDict forKey:tableName];
        }
    }
    return finalDict;
    
}

+(NSDictionary*)getSQLSchemaValues {
    NSDictionary *vals = [self getSQLSchemaValuesForFilepath:@"mondial-schema"];
    return vals;
}


@end
