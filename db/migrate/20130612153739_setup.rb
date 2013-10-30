class Setup < ActiveRecord::Migration

  def up
  
    create_table "virtual_shelf_covers", :force => true do |t|
      t.integer  "cid",        :null => false
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
      t.string   "id_name",    :limit => 20
      t.string   "id_value",   :limit => 20
    end

    add_index "virtual_shelf_covers", ["id_name", "id_value", "cid"], :name => "index_virtual_shelf_covers_on_id_name_and_id_value_and_cid", :unique => true

    create_table "virtual_shelf_records_1", :force => true do |t|
      t.string   "call_number",      :limit => 40
      t.string   "call_number_sort", :limit => 94
      t.string   "document_number",  :limit => 9
      t.string   "isbn",             :limit => 13
      t.string   "oclc",             :limit => 20
      t.string   "title"
      t.text     "summary"
      t.datetime "created_at",       :null => false
      t.datetime "updated_at",       :null => false
      t.text     "contents"
      t.string   "collection_code",  :limit => 20
      t.string   "material_code",    :limit => 20
      t.boolean  "is_serial"
      t.string   "year",             :limit => 4
      t.integer  "call_number_type", :limit => 1
    end

    add_index "virtual_shelf_records_1", [
      "call_number_sort",
      "call_number_type",
      "collection_code",
      "is_serial",
      "material_code"
    ], :name => "index_virtual_shelf_records_multi_column"
    add_index "virtual_shelf_records_1", ["document_number"], {
      :name => "index_virtual_shelf_records_on_document_number",
      :unique => true
    }
    
    create_table "virtual_shelf_supplements", :force => true do |t|
      t.string :document_number, :limit => 10
      t.string :material_code
      t.string :collection_code
      t.integer :call_number_type, :limit => 1
    end
    add_index "virtual_shelf_supplements", [
      "document_number",
      "material_code",
      "collection_code",
      "call_number_type"
    ], {
      :name => "index_virtual_shelf_supplements_multi_column",
      :unique => true
    }
    
  end

  def down
  
    drop_table "virtual_shelf_covers"
    drop_table "virtual_shelf_records_1"
    drop_table "virtual_shelf_supplements"
    
  end
end
