require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'

class SQLObject < MassObject
  extend Searchable
  extend Associatable
  
  @table_name
  def self.set_table_name(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name
  end

  def self.all
    query = <<-SQL
    SELECT *
      FROM #{@table_name}
    SQL
    results = []
    DBConnection.execute(query).each do |row|
      results << Object.const_get(@table_name.camelize.singularize).new(row)
    end
    results
  end

  def self.find(id)
    query = <<-SQL
    SELECT *
      FROM #{@table_name}
     WHERE id = ?
     LIMIT 1
    SQL
    Object.const_get(@table_name.camelize.singularize).new(DBConnection.execute(query, id).first)
  end

  def save
    query = <<-SQL
    SELECT id
      FROM #{ self.class.to_s.underscore}s
     WHERE #{ comma_col_name_eq_value }
    SQL
    
    if send(:id) || !DBConnection.execute(query).empty? # has an id
      update
    else
      create
    end
  end

  private
  def create
    query = <<-SQL
    INSERT INTO #{self.class.to_s.underscore}s (#{ comma_col_names })
         VALUES (#{ comma_col_values })
    SQL
    DBConnection.execute(query)
  end

  def update
    query = <<-SQL
    UPDATE #{ self.class.to_s.underscore }s
       SET #{ comma_col_name_eq_value }
    SQL
    DBConnection.execute(query)
  end
  
  def comma_col_names
    non_id_attributes.map {|at| "'#{at}'"}.join(",")
  end
  
  def comma_col_values
    non_id_attributes.map {|at| "'#{send(at)}'" }.join(",")
  end
  
  def comma_col_name_eq_value
    non_id_attributes.map {|at| "#{at} = '#{send(at)}'" }.join(" AND ")
  end

  def non_id_attributes
    attribute_values.reject{ |at| at == :id}
  end

  def attribute_values
    self.class.attributes
  end
end
