require 'fields_reader'

class FieldsSynchronizerGenerator < Rails::Generator::Base

  def initialize(runtime_args, runtime_options = {})
    super
    @action_to_invoke = runtime_args.shift  
    unless ["init", "sync"].include?(@action_to_invoke)
      STDOUT.puts 'Invalid arguments!'     
      STDOUT.puts banner      
      exit
    end
  end

  def manifest
    recorded_session = record do |m|
      if(@action_to_invoke == "init")
        STDOUT.puts ' init ...'
        unless File.exist? File.join(RAILS_ROOT,'config','fields_dictionary.yml')
          m.template "fields_dictionary.example", "config/fields_dictionary.yml"
        else
         STDOUT.puts "#{RAILS_ROOT}/config/fields_dictionary.yml already exists, override it?(y/n)"
         if gets.chomp =~ /^y/i
           m.template "fields_dictionary.example", "config/fields_dictionary.yml"
         end
        end

      elsif(@action_to_invoke == "sync")

        FieldsReader.init
        skipped_tables = (options[:skipped_table] || []) << "common_fields"
        dictionary = File.join(RAILS_ROOT,'config','fields_dictionary.yml')
        STDOUT.puts " skip table: #{skipped_tables.join(',')}"
        STDOUT.puts " dictionary: #{dictionary}"

        (FieldsReader.keys - skipped_tables).each do |t|
          model = t.singularize.camelize.constantize                     
          table_columns = get_table_columns model
          target_columns = FieldsReader.send t
          removed_columns = get_to_be_deleted_columns(table_columns,target_columns)
          changed_columns = get_changed_columns(table_columns, target_columns)
          added_columns = get_added_columns(table_columns, target_columns)
          unless removed_columns.empty? && changed_columns.empty? && added_columns.empty?
            m.directory "db/migrate"
            migration_name = "#{migration_prefix}_change_table_#{t}"
            m.migration_template 'migration.rb', 'db/migrate',
                               :assigns => { :migration_name => migration_name.camelize,
                                 :removed_columns => removed_columns,
                                 :changed_columns => changed_columns,
                                 :added_columns => added_columns,
                                 :table_name => t
                               },
                               :migration_file_name => migration_name
          end
        end

      end
    end
  end

  def add_options! opt
    opt.on('--skip-table tab1, tab2, tab3 ', Array, 'tables skipped to do synchronization') do |v| 
      options[:skipped_table] = v 
    end
  end

  def banner
    %Q{
      Usage: #{$0} init 
      Usage: #{$0} sync [--skip-table t1,[t2 [,t3]]]"
      Example: #{$0} init
             #{$0} sync
             #{$0} sync --skip-table t1, t2, t3
    }
  end

  private 

  def get_to_be_deleted_columns tab_cols, tgt_cols
    tab_cols_dup = tab_cols.dup
    tab_cols_dup.delete_if{|k,v| tgt_cols.keys.include?(k)}
    tab_cols_dup
  end

  def get_table_columns model
    model.columns.inject({}) do |hash, column|
      hash[column.name] = column
      hash
    end
  end

  def get_changed_columns tab_cols, tgt_cols
    (tab_cols.keys & tgt_cols.keys).inject({}) do |hash, col|
      origin_type = tab_cols[col].type.to_s
      target_type = tgt_cols[col][1]
      if origin_type == target_type
        unless(target_col_options = tgt_cols[col][2]).blank?
          [:null, :default, :limit, :precision, :scale].each do |k|
            next unless target_col_options.keys.include?(k)
            if target_col_options[k] != tab_cols[col].send(k)
              hash[col] = [tgt_cols[col], tab_cols[col]]
              break
            end
          end 
        end 
      else
        hash[col] = [tgt_cols[col], tab_cols[col]]
      end
      hash 
    end
  end

  def get_added_columns tab_cols, tgt_cols
    tgt_dup = tgt_cols.dup
    tgt_dup.delete_if {|k,v| tab_cols.keys.include?(k)}
    tgt_dup
  end

  def migration_prefix
    "sync_#{Time.now.strftime("%y%b%d%a").underscore}_#{('%0.4f' % rand)[2,4]}"
  end

end
