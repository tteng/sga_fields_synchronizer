class FieldsSynchronizerGenerator < Rails::Generator::Base

  def initialize(runtime_args, runtime_options = {})
    p "runtime_args: #{runtime_args}"
    p "runtime_options: #{runtime_options}"
    super
  end

  def mainfest

  end

  def manifesat
    recorded_session = record do |m|
      skipped_tables = options[:skip_table].split(' ') rescue []
      skipped_tables << ["common_fields"]
   
      STDOUT.puts " -"  * 70
      STDOUT.puts " skipped table: #{skipped_tables.join(' ')}"  
      [FieldsReader.keys - skipped_tables].each do |t, columns|
    

      end

      unless options[:skip_migration]
        m.template "models/arter_flow_object.rb", "app/models/arter_flow_object.rb"
        m.directory "db/migrate"
        m.migration_template 'migration.rb', 'db/migrate',
         :assigns => { :migration_name => "CreateArterFlowObjectsTable" },
         :migration_file_name => "create_arter_flow_objects_table"
        m.route_resources :arter_flow_objects
      end
    end
  end

end
