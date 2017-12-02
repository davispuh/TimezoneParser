
CREATE TABLE Timezones (`ID` INTEGER PRIMARY KEY,
                        `Name` TEXT NOT NULL COLLATE NOCASE);
CREATE UNIQUE INDEX IDX_Timezones ON Timezones (`Name`);


CREATE TABLE Territories (`ID` INTEGER PRIMARY KEY,
                      `Territory` TEXT NOT NULL COLLATE NOCASE);
CREATE UNIQUE INDEX IDX_Territories ON Territories (`Territory`);


CREATE TABLE TerritoryContainment (`ID` INTEGER PRIMARY KEY,
                                   `Parent` INTEGER NOT NULL,
                                   `Territory` INTEGER NOT NULL,
                                    FOREIGN KEY(`Parent`) REFERENCES Territories(`ID`),
                                    FOREIGN KEY(`Territory`) REFERENCES Territories(`ID`));
CREATE UNIQUE INDEX IDX_TerritoryContainment ON TerritoryContainment (`Parent`, `Territory`);


CREATE TABLE TimezoneTerritories (`ID` INTEGER PRIMARY KEY,
                              `Timezone` INTEGER NOT NULL,
                              `Territory` INTEGER NOT NULL,
                              FOREIGN KEY(`Territory`) REFERENCES Territories(`ID`));
CREATE UNIQUE INDEX IDX_TimezoneTerritories ON TimezoneTerritories (`Timezone`, `Territory`);


CREATE TABLE Locales (`ID` INTEGER PRIMARY KEY,
                      `Name` TEXT NOT NULL COLLATE NOCASE,
                      `Parent` INTEGER);
CREATE UNIQUE INDEX IDX_Locales ON Locales (`Name`);


CREATE TABLE TimezoneNames (`ID` INTEGER PRIMARY KEY,
                            `Locale` INTEGER NOT NULL,
                            `Name` TEXT NOT NULL COLLATE BINARY,
                            `NameLowercase` TEXT NOT NULL COLLATE NOCASE,
                            `Types` INTEGER,
                            FOREIGN KEY(`Locale`) REFERENCES Locales(`ID`));
CREATE UNIQUE INDEX IDX_TimezoneNames ON TimezoneNames (`Locale`, `Name`);
CREATE INDEX IDX_TimezoneNamesLowercase ON TimezoneNames (`NameLowercase`);


CREATE TABLE Metazones (`ID` INTEGER PRIMARY KEY,
                        `Name` TEXT NOT NULL COLLATE NOCASE);
CREATE UNIQUE INDEX IDX_Metazones ON Metazones (`Name`);


CREATE TABLE MetazonePeriods (`ID` INTEGER PRIMARY KEY,
                              `Metazone` INTEGER NOT NULL,
                              `From` TEXT,
                              `To` TEXT,
                               FOREIGN KEY(`Metazone`) REFERENCES Metazones(`ID`));
CREATE UNIQUE INDEX IDX_MetazonePeriods ON MetazonePeriods (`Metazone`, `From`, `To`);


CREATE TABLE MetazonePeriod_Timezones (`ID` INTEGER PRIMARY KEY,
                                       `MetazonePeriod` INTEGER NOT NULL,
                                       `Timezone` INTEGER NOT NULL,
                                       FOREIGN KEY(`MetazonePeriod`) REFERENCES MetazonePeriods(`ID`),
                                       FOREIGN KEY(`Timezone`) REFERENCES Timezones(`ID`));
CREATE UNIQUE INDEX IDX_MetazonePeriod_Timezones ON MetazonePeriod_Timezones (`MetazonePeriod`, `Timezone`);


CREATE TABLE TimezoneName_Timezones (`ID` INTEGER PRIMARY KEY,
                                     `Name` INTEGER NOT NULL,
                                     `Timezone` INTEGER NOT NULL,
                                     FOREIGN KEY(`Name`) REFERENCES TimezoneNames(`ID`),
                                     FOREIGN KEY(`Timezone`) REFERENCES Timezones(`ID`));
CREATE UNIQUE INDEX IDX_TimezoneName_Timezones ON TimezoneName_Timezones (`Name`, `Timezone`);


CREATE TABLE TimezoneName_Metazones (`ID` INTEGER PRIMARY KEY,
                                     `Name` INTEGER NOT NULL,
                                     `Metazone` INTEGER NOT NULL,
                                     FOREIGN KEY(`Name`) REFERENCES TimezoneNames(`ID`),
                                     FOREIGN KEY(`Metazone`) REFERENCES Metazones(`ID`));
CREATE UNIQUE INDEX IDX_TimezoneName_Metazones ON TimezoneName_Metazones (`Name`, `Metazone`);


CREATE TABLE Abbreviations (`ID` INTEGER PRIMARY KEY,
                            `Name` TEXT NOT NULL COLLATE BINARY,
                            `NameLowercase` TEXT NOT NULL COLLATE NOCASE);
CREATE UNIQUE INDEX IDX_Abbreviations ON Abbreviations (`Name`);
CREATE UNIQUE INDEX IDX_AbbreviationsLowercase ON Abbreviations (`NameLowercase`);


CREATE TABLE AbbreviationOffsets (`ID` INTEGER PRIMARY KEY,
                                  `Abbreviation` INTEGER NOT NULL,
                                  `Offset` INTEGER,
                                  `Types` INTEGER,
                                  `From` TEXT,
                                  `To` TEXT,
                                   FOREIGN KEY(`Abbreviation`) REFERENCES Abbreviations(`ID`));
CREATE UNIQUE INDEX IDX_AbbreviationOffsets ON AbbreviationOffsets (`Abbreviation`, `Offset`, `From`, `To`);


CREATE TABLE AbbreviationOffset_Timezones (`ID` INTEGER PRIMARY KEY,
                                  `Offset` INTEGER NOT NULL,
                                  `Timezone` INTEGER NOT NULL,
                                   FOREIGN KEY(`Offset`) REFERENCES AbbreviationOffsets(`ID`),
                                   FOREIGN KEY(`Timezone`) REFERENCES Timezones(`ID`));
CREATE UNIQUE INDEX IDX_AbbreviationOffset_Timezones ON AbbreviationOffset_Timezones (`Offset`, `Timezone`);


CREATE TABLE AbbreviationOffset_Metazones (`ID` INTEGER PRIMARY KEY,
                                  `Offset` INTEGER NOT NULL,
                                  `Metazone` INTEGER NOT NULL,
                                   FOREIGN KEY(`Offset`) REFERENCES AbbreviationOffsets(`ID`),
                                   FOREIGN KEY(`Metazone`) REFERENCES Metazones(`ID`));
CREATE UNIQUE INDEX IDX_AbbreviationOffset_Metazones ON AbbreviationOffset_Metazones (`Offset`, `Metazone`);


CREATE TABLE RailsTimezones (`ID` INTEGER PRIMARY KEY,
                             `Name` TEXT NOT NULL COLLATE NOCASE,
                             `Timezone` INTEGER NOT NULL,
                             FOREIGN KEY(`Timezone`) REFERENCES Timezones(`ID`));
CREATE UNIQUE INDEX IDX_RailsTimezones ON RailsTimezones (`Name`);


CREATE TABLE RailsI18N (`ID` INTEGER PRIMARY KEY,
                        `Locale` INTEGER NOT NULL,
                        `Name` TEXT NOT NULL COLLATE BINARY,
                        `NameLowercase` TEXT NOT NULL COLLATE NOCASE,
                        `Zone` INTEGER NOT NULL,
                        FOREIGN KEY(`Locale`) REFERENCES Locales(`ID`),
                        FOREIGN KEY(`Zone`) REFERENCES RailsTimezones(`ID`));
CREATE UNIQUE INDEX IDX_RailsI18N ON RailsI18N (`Locale`, `Name`);
CREATE INDEX IDX_RailsI18NName ON RailsI18N (`NameLowercase`);


CREATE TABLE WindowsZones (`ID` INTEGER PRIMARY KEY,
                           `Name` TEXT NOT NULL COLLATE NOCASE,
                           `Standard` INTEGER NOT NULL,
                           `Daylight` INTEGER NOT NULL);
CREATE UNIQUE INDEX IDX_WindowsZones ON WindowsZones (`Name`);


CREATE TABLE WindowsZone_Timezones (`ID` INTEGER PRIMARY KEY,
                                    `Zone` INTEGER NOT NULL,
                                    `Territory` INTEGER NOT NULL,
                                    `Timezone` INTEGER NOT NULL,
                                    FOREIGN KEY(`Zone`) REFERENCES WindowsZones(`ID`),
                                    FOREIGN KEY(`Territory`) REFERENCES Territories(`ID`),
                                    FOREIGN KEY(`Timezone`) REFERENCES Timezones(`ID`));
CREATE UNIQUE INDEX IDX_WindowsZone_Timezones ON WindowsZone_Timezones (`Zone`, `Territory`, `Timezone`);


CREATE TABLE WindowsZoneNames (`ID` INTEGER PRIMARY KEY,
                               `Locale` INTEGER NOT NULL,
                               `Name` TEXT NOT NULL COLLATE BINARY,
                               `NameLowercase` TEXT NOT NULL COLLATE NOCASE,
                               `Types` INTEGER,
                               FOREIGN KEY(`Locale`) REFERENCES Locales(`ID`));
CREATE UNIQUE INDEX IDX_WindowsZoneNames ON WindowsZoneNames (`Locale`, `Name`);
CREATE INDEX IDX_WindowsZoneNamesLowercase ON WindowsZoneNames (`NameLowercase`);


CREATE TABLE WindowsZoneName_Zones (`ID` INTEGER PRIMARY KEY,
                                    `Name` INTEGER NOT NULL,
                                    `Zone` INTEGER NOT NULL,
                                    FOREIGN KEY(`Name`) REFERENCES WindowsZoneNames(`ID`),
                                    FOREIGN KEY(`Zone`) REFERENCES WindowsZones(`ID`));
CREATE UNIQUE INDEX IDX_WindowsZoneName_Zones ON WindowsZoneName_Zones (`Name`, `Zone`);

