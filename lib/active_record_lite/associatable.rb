require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  attr_accessor :other_class_name, :other_table, :foreign_key, :primary_key
  def other_class
    @other_class_name.constantize
  end

  def other_table
    "#{@other_class_name.underscore}s"
  end
end

class BelongsToAssocParams < AssocParams
  # SELECT humans.* FROM cats JOIN humans ON cats.human_id = humans.id LIMIT 1
  def initialize(name, params)
    @other_class_name = params[:class_name] || "#{name.to_s}".camelize.singularize
    @primary_key = params[:primary_key] || "id"    
    @foreign_key = params[:foreign_key] || "#{@other_class_name.underscore}_id"
  end

  def type
    
  end
end

class HasManyAssocParams < AssocParams
  # SELECT cats.* FROM humans JOIN cats ON cats.human_id = humans.id
  def initialize(name, params, self_class)
      @other_class_name = params[:class_name] || "#{name.to_s}".camelize.singularize
      @primary_key = params[:primary_key] || "id"
      @foreign_key = params[:foreign_key] || "#{self_class.to_s.underscore}_id"      
  end

  def type
  end
end

module Associatable
  def assoc_params
    @assoc_params ||= {}
  end
  
  def has_many(name, params = {})
    aps = HasManyAssocParams.new(name, params, self)
    assoc_params[name] = aps
    define_method(name) do
      query = <<-SQL
        SELECT *
          FROM #{aps.other_table}
         WHERE #{aps.other_table}.#{aps.foreign_key} = ?
      SQL
      results = DBConnection.execute(query, self.send(aps.primary_key))
      aps.other_class.parse_all(results)
    end
    aps
  end

  def belongs_to(name, params = {})
    aps = BelongsToAssocParams.new(name, params)
    assoc_params[name] = aps
    define_method(name) do
      query = <<-SQL
        SELECT *
          FROM #{aps.other_table}
         WHERE #{aps.other_table}.#{aps.primary_key} = ?
      SQL
      aps.other_class.parse_all(DBConnection.execute(query, self.send(aps.primary_key)))
    end
    aps
  end

  def has_one_through(name, assoc1, assoc2) #Cat has_one_thru house,human,house 
    define_method(name) do
      assoc1_params = self.class.assoc_params[assoc1]
      assoc2_params = assoc1_params.other_class_name.constantize.assoc_params[assoc2]
      query = <<-SQL
      SELECT #{assoc2_params.other_table}.*
        FROM #{assoc2_params.other_table}
        JOIN #{assoc1_params.other_table}
          ON #{assoc1_params.other_table}.#{assoc2_params.foreign_key}
           = #{assoc2_params.other_table}.#{assoc2_params.primary_key}
       WHERE #{assoc1_params.other_table}.#{assoc2_params.primary_key} 
           = ?
      SQL
      assoc2_params.other_class_name
                   .constantize
                   .parse_all(DBConnection.execute(query, self.send(assoc1_params.foreign_key)))    
    end
  end
end