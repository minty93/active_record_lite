require_relative 'searchable'
require 'active_support/inflector'


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
    @assoc_options
  end


end

class SQLObject
  extend Associatable
end