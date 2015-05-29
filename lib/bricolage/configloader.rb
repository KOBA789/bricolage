require 'bricolage/sqlstatement'
require 'bricolage/resource'
require 'bricolage/exception'
require 'pathname'
require 'yaml'
require 'erb'
require 'date'

module Bricolage

  class ConfigLoader
    def ConfigLoader.load_eruby_yaml(path)
      new(nil).load_eruby_yaml(path)
    end

    def initialize(app_home)
      @app_home = app_home
      @base_dir = Pathname('.')
    end

    def load_eruby(path)
      eruby(read_file(path), path)
    end

    def load_eruby_yaml(path)
      parse_yaml(load_eruby(path), path)
    end

    def load_yaml(path)
      parse_yaml(read_file(path), path)
    end

    def parse_yaml(text, path)
      YAML.load(text)
    rescue => err
      raise ParameterError, "#{path}: config file syntax error: #{err.message}"
    end

    def eruby(text, path)
      erb = ERB.new(text, nil, '%-')
      erb.filename = path.to_s
      push_base_dir(path) {
        erb.result(binding())
      }
    end

    def eval_file(path)
      push_base_dir(path) {
        instance_eval(File.read(path), path.to_s, 1)
      }
    end

    def read_file(path)
      File.read(path)
    rescue SystemCallError => err
      raise ParameterError, "could not read file: #{err.message}"
    end

    private

    def app_home
      @app_home or raise ParameterError, "app_home is not given in this file"
    end

    def base_dir
      @base_dir
    end

    def push_base_dir(path)
      saved, @base_dir = @base_dir, Pathname(path).parent
      begin
        yield
      ensure
        @base_dir = saved
      end
    end
  end

  module EmbeddedCodeAPI
    private

    def user_home
      Pathname(ENV['HOME'])
    end

    def user_home_relative_path(rel)
      user_home + rel
    end

    def app_home_relative_path(rel)
      app_home + rel
    end

    def relative_path(rel)
      base_dir + rel
    end

    def read_file_if_exist(path)
      return nil unless File.exist?(path)
      File.read(path)
    end

    def date(str)
      Date.parse(str)
    end

    def ymd(date)
      date.strftime('%Y-%m-%d')
    end

    def attribute_tables(attr)
      all_tables.select {|table| table.attributes.include?(attr) }
    end

    def all_tables
      Dir.glob("#{app_home}/*/*.ct").map {|path|
        SQLStatement.new(FileResource.new(path))
      }
    end
  end

  class ConfigLoader
    include EmbeddedCodeAPI
  end

end
