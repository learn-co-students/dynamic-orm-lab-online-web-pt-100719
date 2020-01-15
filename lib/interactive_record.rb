require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def self.table_name
    self.to_s.pluralize.downcase
  end

  def self.column_names
    DB[:conn].results_as_hash = true
    table_info = DB[:conn].execute("pragma table_info('#{table_name}')")
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
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
    new = []
    self.class.column_names.each do |col_name|
      new << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    new.join(", ")
  end

  def save
    DB[:conn].execute("INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})")
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = ?", name)
  end

  def self.find_by(attr)
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE #{attr.keys.first} = ?", attr.values.first)
  end
end