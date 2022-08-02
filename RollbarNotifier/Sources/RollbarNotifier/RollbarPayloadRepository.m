#import "RollbarPayloadRepository.h"

#import "RollbarNotifierFiles.h"

@import RollbarCommon;

#import "sqlite3.h"

//======================================================================================================================
#pragma mark - Sqlite command execution callbacks
#pragma mark -
//======================================================================================================================

typedef int (^SqliteCallback)(void *info, int columns, char **data, char **column);

static int defaultOnSelectCallback(void *info, int columns, char **data, char **column)
{
    RollbarSdkLog(@"Columns: %d", columns);
    for (int i = 0; i < columns; i++) {
        RollbarSdkLog(@"Column: %s", column[i]);
        RollbarSdkLog(@"Data: %s", data[i]);
    }
    
    return SQLITE_OK;
}

static int checkIfTableExistsCallback(void *info, int columns, char **data, char **column)
{
    defaultOnSelectCallback(info, columns, data, column);
    
    BOOL *answerFlag = (BOOL *)info;
    if (answerFlag) {

        *answerFlag = (columns > 0) ? YES : NO;
    }
    
    return SQLITE_OK;
}

static int addDestinationCallback(void *info, int columns, char **data, char **column)
{
    defaultOnSelectCallback(info, columns, data, column);

    return SQLITE_OK;
}

static int getDestinationCallback(void *info, int columns, char **data, char **column)
{
    defaultOnSelectCallback(info, columns, data, column);

    //NSMutableDictionary<NSString *, NSString *> *row = [NSMutableDictionary<NSString *, NSString *> dictionaryWithCapacity:columns];
    //info = row;
    NSDictionary<NSString *, NSString *> *__strong*result = (NSDictionary<NSString *, NSString *> *__strong*)info;
    //*result = [NSMutableDictionary<NSString *, NSString *> dictionaryWithCapacity:columns];
    
    NSMutableDictionary<NSString *, NSString *> *row =
    [NSMutableDictionary<NSString *, NSString *> dictionaryWithCapacity:columns];
    
    for (int i = 0; i < columns; i++) {
        NSString *key = [NSString stringWithFormat:@"%s", column[i]];
        NSString *value = [NSString stringWithFormat:@"%s", data[i]];
        row[key] = value;
    }
    
    *result = [row copy];

    return SQLITE_OK;
}

static int getAllDestinationsCallback(void *info, int columns, char **data, char **column)
{
    defaultOnSelectCallback(info, columns, data, column);

    //NSMutableArray<NSDictionary<NSString *, NSString *> *> *result = nil;
    
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *__strong*result =
    (NSMutableArray<NSDictionary<NSString *, NSString *> *> *__strong*)info;
    if (!*result) {
        *result = [NSMutableArray<NSDictionary<NSString *, NSString *> *> array];
    }
    
    NSMutableDictionary<NSString *, NSString *> *row =
    [NSMutableDictionary<NSString *, NSString *> dictionaryWithCapacity:columns];
        
    for (int i = 0; i < columns; i++) {
        NSString *key = [NSString stringWithFormat:@"%s", column[i]];
        NSString *value = [NSString stringWithFormat:@"%s", data[i]];
        row[key] = value;
    }
    
    [*result addObject:[row copy]];
    
    return SQLITE_OK;
}

//======================================================================================================================
#pragma mark - Peyloads Repository
#pragma mark -
//======================================================================================================================

/// Peristent Rollbar  payloads repository
@implementation RollbarPayloadRepository {
    
    @private
    NSString *_storePath;
    sqlite3 *_db;
    char *_sqliteErrorMessage;

}

+ (void)initialize {
    
}

#pragma mark - instance initializers

- (instancetype)initWithStore:(nonnull NSString *)storePath {
    
    if (self = [super init]) {
        
        self->_storePath = storePath;
        [self initDB];
        return self;
    }
    
    return nil;
}

- (instancetype)init {

    // create working cache directory:
    [RollbarCachesDirectory ensureCachesDirectoryExists];
    NSString *cachesDirectory = [RollbarCachesDirectory directory];
    NSString *storePath = [cachesDirectory stringByAppendingPathComponent:[RollbarNotifierFiles payloadsStore]];

    if (self = [self initWithStore:storePath]) {
        
        return self;
    }
    
    return nil;
}

#pragma mark - repository methods

- (void)addPayload:(nonnull RollbarPayload *)payload {
    
}

- (void)clear {
    
}

#pragma mark - internal methods

- (void)initDB {
    
    [self openDB];
    [self ensureDestinationsTable];
    [self ensurePayloadsTable];
}

- (void)openDB {
    
    int result = sqlite3_open([self->_storePath UTF8String], &self->_db);
    if (result != SQLITE_OK) {
        
        RollbarSdkLog(@"sqlite3_open: %s", sqlite3_errmsg(self->_db));
    }
}

- (void)ensureDestinationsTable {
    
    NSString *sql = [NSString stringWithFormat:
                     @"CREATE TABLE IF NOT EXISTS destinations (id INTEGER NOT NULL PRIMARY KEY, endpoint TEXT NOT NULL, access_token TEXT NOT NULL, CONSTRAINT unique_destination UNIQUE(endpoint, access_token))"
    ];
    [self executeSql:sql];
}

- (void)ensurePayloadsTable {

    
    
    NSString *sql = [NSString stringWithFormat:
                     @"CREATE TABLE IF NOT EXISTS payloads (id INTEGER NOT NULL PRIMARY KEY, config_json TEXT NOT NULL, payload_json TEXT NOT NULL, created_at INTEGER NOT NULL, destination_key INTEGER NOT NULL, FOREIGN KEY(destination_key) REFERENCES destinations(id) ON UPDATE CASCADE ON DELETE CASCADE)"
    ];
    [self executeSql:sql];
}

- (nullable NSDictionary<NSString *, NSString *> *)addDestinationWithEndpoint:(nonnull NSString *)endpoint
                                                                andAccesToken:(nonnull NSString *)accessToken {
    
    NSString *sql = [NSString stringWithFormat:
                     @"INSERT INTO destinations (endpoint, access_token) VALUES ('%@', '%@')",
                     endpoint,
                     accessToken
    ];

    char *sqliteErrorMessage;
    int sqlResult = sqlite3_exec(self->_db, [sql UTF8String], addDestinationCallback, NULL, &sqliteErrorMessage);
    if (sqlResult != SQLITE_OK) {

        RollbarSdkLog(@"sqlite3_exec: %s during %@", sqliteErrorMessage, sql);
        sqlite3_free(sqliteErrorMessage);
        return nil;
    }
    
    sqlite3_int64 destinationID = sqlite3_last_insert_rowid(self->_db);

    return @ {
        @"id": [NSString stringWithFormat:@"%lli", destinationID], //[NSNumber numberWithLongLong:destinationID],
        @"endpoint": endpoint,
        @"access_token": accessToken
    };
}

- (nullable NSDictionary<NSString *, NSString *> *)getDestinationWithEndpoint:(nonnull NSString *)endpoint
                                                                andAccesToken:(nonnull NSString *)accessToken {
    
    NSString *sql = [NSString stringWithFormat:
                         @"SELECT * FROM destinations WHERE endpoint = '%@' AND access_token = '%@'",
                     endpoint,
                     accessToken
    ];
                                               
    NSDictionary<NSString *, NSString *> *result = nil;
    
    char *sqliteErrorMessage;
    NSDictionary<NSString *, NSString *> *selectedRow = nil;
    int sqlResult = sqlite3_exec(self->_db, [sql UTF8String], getDestinationCallback, &result, &sqliteErrorMessage);
    if (sqlResult != SQLITE_OK) {

        RollbarSdkLog(@"sqlite3_exec: %s during %@", sqliteErrorMessage, sql);
        sqlite3_free(sqliteErrorMessage);
    }
    
    return result;
}

- (nullable NSDictionary<NSString *, NSString *> *)getDestinationByID:(nonnull NSString *)destinationID {
    
    NSString *sql = [NSString stringWithFormat:
                     @"SELECT * FROM destinations WHERE id = '%@'",
                     destinationID
    ];
    
    NSDictionary<NSString *, NSString *> *result = nil;
    
    char *sqliteErrorMessage;
    NSDictionary<NSString *, NSString *> *selectedRow = nil;
    int sqlResult = sqlite3_exec(self->_db, [sql UTF8String], getDestinationCallback, &result, &sqliteErrorMessage);
    if (sqlResult != SQLITE_OK) {
        
        RollbarSdkLog(@"sqlite3_exec: %s during %@", sqliteErrorMessage, sql);
        sqlite3_free(sqliteErrorMessage);
    }
    
    return result;
}



//int (*callback)(void*,int,char**,char**)
- (NSDictionary<NSString *, NSString *> *)selectSingleRowWithSql:(NSString *)sql
                                                     andCallback:(int(*)(void*,int,char**,char**))callback {
    
    NSDictionary<NSString *, NSString *> *result = nil;
    char *sqliteErrorMessage;
    NSDictionary<NSString *, NSString *> *selectedRow = nil;
    int sqlResult = sqlite3_exec(self->_db, [sql UTF8String], callback, &result, &sqliteErrorMessage);
    if (sqlResult != SQLITE_OK) {
        
        RollbarSdkLog(@"sqlite3_exec: %s during %@", sqliteErrorMessage, sql);
        sqlite3_free(sqliteErrorMessage);
    }
    
    return result;
}







- (nonnull NSArray<NSDictionary<NSString *, NSString *> *> *)getAllDestinations {
    
    NSString *sql = @"SELECT * FROM destinations";
    
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *result = nil;
    
    char *sqliteErrorMessage;
    //NSDictionary<NSString *, NSString *> *selectedRow = nil;
    int sqlResult = sqlite3_exec(self->_db, [sql UTF8String], getAllDestinationsCallback, &result, &sqliteErrorMessage);
    if (sqlResult != SQLITE_OK) {
        
        RollbarSdkLog(@"sqlite3_exec: %s during %@", sqliteErrorMessage, sql);
        sqlite3_free(sqliteErrorMessage);
    }
    
    if (result) {
        return [result copy];
    }
    else {
        return [NSArray<NSDictionary<NSString *, NSString *> *> array];
    }
}







- (void)releaseDB {
    
    sqlite3_close(self->_db);
    self->_db = nil;
}

- (void)clearDestinationsTable {
}

- (void)clearPayloadsTable {
}

- (void)clearPayloadsOlderThan:(nonnull NSDate *)cutoffTime {
}

- (void)executeSql:(nonnull NSString *)sql {
    
    char *sqliteErrorMessage;
    int sqlResult = sqlite3_exec(self->_db, [sql UTF8String], NULL, NULL, &sqliteErrorMessage);
    if (sqlResult != SQLITE_OK) {
        
        RollbarSdkLog(@"sqlite3_exec: %s during %@", sqliteErrorMessage, sql);
        sqlite3_free(sqliteErrorMessage);
    }
}

- (BOOL)checkIfTableExists_Destinations {
    
    BOOL result = [self checkIfTableExists:@"destinations"];
    return result;
}

- (BOOL)checkIfTableExists_Payloads {
    
    BOOL result = [self checkIfTableExists:@"payloads"];
    return result;
}

- (BOOL)checkIfTableExists_Unknown {
    
    BOOL result = [self checkIfTableExists:@"unknown"];
    return result;
}


- (BOOL)checkIfTableExists:(nonnull NSString *)tableName {
    
    NSString *sql = [NSString stringWithFormat:
                     @"SELECT name FROM sqlite_master WHERE type='table' AND name='%@'", tableName];
    char *sqliteErrorMessage;
    BOOL answerFlag = NO;
    int sqlResult = sqlite3_exec(self->_db, [sql UTF8String], checkIfTableExistsCallback, &answerFlag, &sqliteErrorMessage);
    if (sqlResult != SQLITE_OK) {
        
        RollbarSdkLog(@"sqlite3_exec: %s during %@", sqliteErrorMessage, sql);
        sqlite3_free(sqliteErrorMessage);
    }
    
    return answerFlag;
}

@end
