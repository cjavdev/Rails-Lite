require_relative './db_connection'

module Searchable  
  def where(params)
    name_eq_vals = params.map{|col, val| "#{col} = '#{val}'"}.join(" AND ")
    
    query = <<-SQL
    SELECT *
    FROM #{self.to_s.underscore.pluralize}
    WHERE #{name_eq_vals}
    SQL
    
    results = []
    DBConnection.execute(query).each do |row|
      results << Object.const_get(self.to_s).new(row)
    end
    results
  end
end