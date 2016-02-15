require_relative 'db_connection'
require_relative 'sql_object'

module Searchable
  def where(params)

    keys = params.keys

    where_params = keys.map { |key| "#{key} = ?" }
    where_params = where_params.join(" AND ")

    results = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_params}
    SQL

    parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
