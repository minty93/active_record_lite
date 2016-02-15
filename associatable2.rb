require_relative 'associatable'

module Associatable

  def has_one_through(name, through_name, source_name)
     through_options = self.class.assoc_options[through_name]
     define_method(name) do
       source_options = through_options.model_class.assoc_options[source_name]
       source_class = source_options.model_class
       source_table_name = source_class.table_name
       source_foreign_key = source_options.foreign_key
       source_primary_key = source_options.primary_key

       through_table_name = through_class.table_name
       through_primary_key = through_options.primary_key
       through_foreign_key = through_options.foreign_key

       result = DBConnection.execute(<<-SQL, self.send(through_foreign_key))
         SELECT
           #{source_table_name}.*
         FROM
           #{through_table_name}
         JOIN
           #{source_table_name}
         ON
           #{through_table_name}.#{source_options.foreign_key} = #{source_table_name}.#{source_options.primary_key}
         WHERE
           #{through_table}.#{through_options.primary_key} = ?
       SQL

       source_class.parse_all(result)

     end

  end
end
