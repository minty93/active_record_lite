require_relative 'searchable'
require 'active_support/inflector'
require 'byebug'



class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    preset = {
      foreign_key: "#{name.singularize}_id".to_sym,
      class_name: name.singularize.capitalize,
      primary_key: :id
    }
    self.send("foreign_key=", options[:foreign_key] || preset[:foreign_key])
    self.send("class_name=", options[:class_name] || preset[:class_name])
    self.send("primary_key=", options[:primary_key] || preset[:primary_key])

  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    preset = {
      foreign_key: "#{self_class_name.singularize.underscore}_id".to_sym,
      class_name: name.singularize.capitalize,
      primary_key: :id
    }

    self.send("foreign_key=", options[:foreign_key] || preset[:foreign_key])
    self.send("class_name=", options[:class_name] || preset[:class_name])
    self.send("primary_key=", options[:primary_key] || preset[:primary_key])
  end
end

module Associatable

  def belongs_to(name, options = {})
    options = BelongsToOptions(name, options)
    assoc_options[name] = options
    define_method(name) do
      foreign_key_value = self.send("#{options.foreign_key}")
      target_class = options.model_class
      target_class.where(options.primary_key => foreign_key_value).first
    end
  end

  def has_many(name, options = {})
  options = HasManyOptions.new(name, self.to_s, options)
  define_method(name) do
    foreign_key_value = self.send("#{options.primary_key}")
    target_class = options.model_class
    target_class.where(options.foreign_key => foreign_key_value)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end


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

class SQLObject
  extend Associatable
end
