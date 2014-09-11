module SerializationHelper

  class Base
    attr_reader :extension

    def initialize(helper)
      @dumper = helper.dumper
      @loader = helper.loader
      @extension = helper.extension
    end

    def dump(filename)
      disable_logger
      @dumper.dump(File.new(filename, "w"))
      reenable_logger
    end

    def dump_to_dir(dirname)
      Dir.mkdir(dirname)
      tables = @dumper.tables
      tables.each do |table|
        io = File.new "#{dirname}/#{table}.#{@extension}", "w"
        @dumper.before_table(io, table)
        @dumper.dump_table io, table
        @dumper.after_table(io, table)         
      end
    end

    def load(filename, truncate = true)
      disable_logger
      @loader.load(File.new(filename, "r"), truncate)
      reenable_logger
    end

    def load_from_dir(dirname, truncate = true)
      Dir.entries(dirname).each do |filename|
        if filename =~ /^[.]/
          next
        end
        @loader.load(File.new("#{dirname}/#{filename}", "r"), truncate)
      end   
    end

    def disable_logger
      @@old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
    end

    def reenable_logger
      ActiveRecord::Base.logger = @@old_logger
    end
  end
  
  class Load
    def self.load(io, truncate = true)
      ActiveRecord::Base.connection.transaction do
        load_documents(io, truncate)
      end
    end

    def self.truncate_table(table)
      begin
        ActiveRecord::Base.connection.execute("TRUNCATE #{SerializationHelper::Utils.quote_table(table)}")
      rescue Exception
        ActiveRecord::Base.connection.execute("DELETE FROM #{SerializationHelper::Utils.quote_table(table)}")
      end
    end

    def self.load_table(table, data, truncate = true)
      column_names = data['columns']
      if truncate
        truncate_table(table)
      end
      load_records(table, column_names, data['records'])
      reset_pk_sequence!(table)
    end

    def self.load_records(table, column_names, records)
      if column_names.nil?
        return
      end
      columns = column_names.map{|cn| ActiveRecord::Base.connection.columns(table).detect{|c| c.name == cn}}
      quoted_column_names = column_names.map { |column| ActiveRecord::Base.connection.quote_column_name(column) }.join(',')
      quoted_table_name = SerializationHelper::Utils.quote_table(table)
      records.each do |record|
        quoted_values = record.zip(columns).map{|c| ActiveRecord::Base.connection.quote(c.first, c.last)}.join(',')
        ActiveRecord::Base.connection.execute("INSERT INTO #{quoted_table_name} (#{quoted_column_names}) VALUES (#{quoted_values})")
      end
    end

    def self.reset_pk_sequence!(table_name)
      if ActiveRecord::Base.connection.respond_to?(:reset_pk_sequence!)
        ActiveRecord::Base.connection.reset_pk_sequence!(table_name)
      end
    end    

      
  end

  module Utils

    def self.unhash(hash, keys)
      keys.map { |key| hash[key] }
    end

    def self.unhash_records(records, keys)
      records.each_with_index do |record, index|
        records[index] = unhash(record, keys)
      end

      records
    end

    def self.convert_arrays(records, columns)
      records.each do |record|
        columns.each do |column|
          next unless is_array(record[column[0]])
          record[column[0]] = convert_array(record[column[0]], column[1])
        end
      end
      records
    end

    def self.array_columns(table)
      columns = ActiveRecord::Base.connection.columns(table).reject { |c| silence_warnings { !c.try(:array) } }
      columns.map { |c| [ c.name, c.type ] }
    end

    def self.convert_array(value, type)
      if type == :integer
        value[1..-2].split(',').map { |v| v.to_i}
      elsif type == :boolean
        value[1..-2].split(',').map { |v| ['t', '1', 'true', true, 1].include?(v) }
      else
        value[1..-2].split(',')
      end
    end

    def self.is_array(value)
      value.kind_of?(String) and ((value =~ /^\{.*\}$/) == 0)
    end

    def self.convert_booleans(records, columns)
      records.each do |record|
        columns.each do |column|
          next if is_boolean(record[column])
          record[column] = convert_boolean(record[column])
        end
      end
      records
    end

    def self.convert_boolean(value)
      ['t', '1', 'true', true, 1].include?(value)
    end

    def self.boolean_columns(table)
      columns = ActiveRecord::Base.connection.columns(table).reject { |c| silence_warnings { (c.type != :boolean) or c.try(:array) } }
      columns.map { |c| c.name }
    end

    def self.is_boolean(value)
      value.kind_of?(TrueClass) or value.kind_of?(FalseClass)
    end

    def self.convert_hstores(records, columns)
      records.each do |record|
        columns.each do |column|
          record[column] = convert_hstore(record[column])
        end
      end
      records
    end

    def self.convert_hstore(value)
      unless value.blank?
        # This converts a string like '"aa"=>"bb", "cc"=>"dd","ee"=>"ff"' to a hash.
        # The algorithm is as following:
        #
        # 1) Get rid of left and right spaces (strip)
        # 2) replace '=>' with ',' (first gsub)
        # 3) replace ', ' with ',' (second gsub)
        # 4) get rid of the first and the last '"' ([1..-2])
        # 5) extract each individual arguments in an array (split)
        # 6) transmit the array as a list of parameters to the Hash class (Hash[*...])
        #
        Hash[*value.strip.gsub('=>', ',').gsub('", "', '","')[1..-2].split('","')]
      else
        {}
      end
    end

    def self.hstore_columns(table)
      columns = ActiveRecord::Base.connection.columns(table).reject { |c| silence_warnings { c.type != :hstore } }
      columns.map { |c| c.name }
    end

    def self.quote_table(table)
      ActiveRecord::Base.connection.quote_table_name(table)
    end

  end

  class Dump
    def self.before_table(io, table)

    end

    def self.dump(io)
      tables.each do |table|
        before_table(io, table)
        dump_table(io, table)
        after_table(io, table)
      end
    end

    def self.after_table(io, table)

    end

    def self.tables
      ActiveRecord::Base.connection.tables.reject { |table| ['schema_info', 'schema_migrations'].include?(table) }
    end

    def self.dump_table(io, table)
      return if table_record_count(table).zero?

      dump_table_columns(io, table)
      dump_table_records(io, table)
    end

    def self.table_column_names(table)
      ActiveRecord::Base.connection.columns(table).map { |c| c.name }
    end


    def self.each_table_page(table, records_per_page=1000)
      total_count = table_record_count(table)
      pages = (total_count.to_f / records_per_page).ceil - 1
      id = table_column_names(table).first
      boolean_columns = SerializationHelper::Utils.boolean_columns(table)
      array_columns = SerializationHelper::Utils.array_columns(table)
      hstore_columns = SerializationHelper::Utils.hstore_columns(table)
      quoted_table_name = SerializationHelper::Utils.quote_table(table)

      (0..pages).to_a.each do |page|
        query = Arel::Table.new(table).order(id).skip(records_per_page*page).take(records_per_page).project(Arel.sql('*'))
        records = ActiveRecord::Base.connection.select_all(query)
        records = SerializationHelper::Utils.convert_booleans(records, boolean_columns)
        records = SerializationHelper::Utils.convert_arrays(records, array_columns)
        records = SerializationHelper::Utils.convert_hstores(records, hstore_columns)
        yield records
      end
    end

    def self.table_record_count(table)
      ActiveRecord::Base.connection.select_one("SELECT COUNT(*) FROM #{SerializationHelper::Utils.quote_table(table)}").values.first.to_i
    end

  end

end
