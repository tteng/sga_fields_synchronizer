require 'yaml'

class FieldsReader

  YAML_PATH = File.join(RAILS_ROOT, "config", "fields_dictionary.yml")

  class << self

    def init reload=false
      raise "Missing Config File, Please Check Whether #{YAML_PATH} exists." unless File.exists?(YAML_PATH)
      if reload 
        @@config = YAML.load_file(YAML_PATH)["configs"]
      else
        @@config ||= YAML.load_file(YAML_PATH)["configs"]
      end
    end

    def method_missing mth, *args
      if mth.to_s =~ /^(.*)=$/ 
        @@config[$1] = args.first
      else
        @@config.respond_to?(mth) ? @@config.send(mth) : @@config[mth.to_s]
      end
    end

    def write_back
      File.open(YAML_PATH,'w'){|f| YAML.dump({"configs" => @@config},f)}
      init(true)
    end

  end

end
