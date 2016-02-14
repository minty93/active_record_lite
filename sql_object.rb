require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'


class SQLObject
  def self.columns
    return @col if @col
    @cols = DBConnection.execute2(<<-SQL)
    SELECT
      *
    FROM
      #{self.table_name}
    SQL
    @col = @cols.first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |col|
      define_method("#{col}") {
        @attributes[col]
      }

      define_method("#{col}=") { |val|
        self.attributes
        @attributes[col] = val
      }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    # ...
  end

  def self.parse_all(results)
    # ...
  end

  def self.find(id)
    # ...
  end

  def initialize(params = {})
    self.class.columns
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      if @cols.include?(attr_name)
        self.send("#{attr_name}=", value)
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    # ...
  end

  def insert
    # ...
  end

  def update
    # ...
  end

  def save
    # ...
  end
end
