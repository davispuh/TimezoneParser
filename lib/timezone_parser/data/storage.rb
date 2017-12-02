# encoding: utf-8
require 'date'
require 'insensitive_hash'
require 'sqlite3'

module TimezoneParser
    class Data
        # Timezone data Storage class
        class Storage
            protected
            @@Database = nil
            @@Statements = {}

            public

            DatabaseName = 'timezones.db'

            def self.Database
                unless @@Database
                    @@Database = SQLite3::Database.new((Data::DataDir + DatabaseName).to_s, { readonly: true } )
                end
                @@Database
            end

            def self.getStatement(statement)
                unless @@Statements.has_key?(statement)
                    @@Statements[statement] = self.Database.prepare(statement)
                end
                @@Statements[statement]
            end

        end
    end
end
