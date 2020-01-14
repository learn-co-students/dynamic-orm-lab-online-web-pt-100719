require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = <<-SQL
      PRAGMA table_info('#{table_name}')
    SQL

    column_names = []
    DB[:conn].execute(sql).map do |column|
      column_names << column["name"]
  end

    column_names.compact
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  def save
    sql = <<-SQL
      INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert})
      VALUES (#{values_for_insert});
    SQL
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end
  
  def self.find_by_name(name) 
    DB[:conn].execute("SELECT * FROM #{self.table_name} 
    WHERE name = ?", [name])
  end
  
  def self.find_by(attribute)
    column = attribute.keys[0].to_s
    value = attribute.values[0]
   
    sql = <<-SQL
    SELECT * FROM #{table_name} 
    WHERE #{column} = ?
    SQL
    
    DB[:conn].execute(sql, value)
  end 
  
end