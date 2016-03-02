require_relative 'db_connection'
require 'active_support/inflector'


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
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
     end
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL
    return nil if result.empty?
    self.new(result[0])
  end

  def initialize(params = {})
    col = self.class.columns
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      if col.include?(attr_name)
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

    @attributes.values
  end

  def insert
    cols = self.class.columns
    cols = cols.drop(1)
    col_names = cols.map do |col|
      col.to_s
    end
    col_names = col_names.join(", ")
    vals = attribute_values
    question = (["?"] * cols.length).join(", ")
    table_name = self.class.table_name
    DBConnection.execute(<<-SQL, *vals)
      INSERT INTO
        #{table_name} (#{col_names})
      VALUES
        (#{question})

    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    columns = self.class.columns
      .map { |attr| "#{attr} = ?" }.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{columns}
      WHERE
        #{self.class.table_name}.id = ?
    SQL

  end

  def save
    if self.id.nil?
      insert
    else
      update
    end
  end
end
