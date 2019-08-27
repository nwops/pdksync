require 'yaml'
require 'pdk/version'
require 'ostruct'

# @summary
#   A class used to contain a set of configuration variables 
# @note
#   Configuration is loaded from `$HOME/.pdksync.yml`. If $HOME is not set, the config_path will use the current directory.
#   The configuration filename and path can be overridden with env variable PDK_CONFIG_PATH
#   Set PDKSYNC_LABEL to '' to disable adding a label during pdksync runs.
module PdkSync 
  class Configuration < OpenStruct
    SUPPORTED_SCM_PLATFORMS = [:github, :gitlab]
    PDKSYNC_FILE_NAME = 'pdksync.yml'
    DEFAULT_CONFIG = {
      namespace: 'puppetlabs',
      pdksync_dir: 'modules_pdksync',
      push_file_destination: 'origin',
      create_pr_against: 'master',
      managed_modules: 'managed_modules.yml',
      pdksync_label: 'maintenance',
      git_platform: :github,
      git_base_uri: 'https://github.com',
      gitlab_api_endpoint: 'https://gitlab.com/api/v4',
    }
    
    # @param config_path [String] -  the path to the pdk config file
    def initialize(config_path = ENV['PDK_CONFIG_PATH'])
      @config_path = locate_config_path(config_path)
      @custom_config = DEFAULT_CONFIG.merge(custom_config(@config_path))
      super(@custom_config)
      valid_scm?(git_platform)
      valid_access_token?
    end

    # @return [Hash] - returns the access settings for git scm
    def git_platform_access_settings 
      @git_platform_access_settings ||= {
        access_token: access_token,
        gitlab_api_endpoint: gitlab_api_endpoint
      }
    end

    # @param path [String] path to the pdksync config file in yaml format
    # @return [Hash] the custom configuration as a hash
    def custom_config(path = nil)
      begin
        return {} unless path
        return {} unless File.exist?(path)
        c = (YAML.load_file(path) || {}).transform_keys_to_symbols
        c[:git_base_uri] ||= 'https://gitlab.com' if c[:git_platform].eql?(:gitlab)
        c
      end
    end

    # @return [String] the path the pdksync config file, nil if not found
    def locate_config_path(custom_file)
      files = [ 
          custom_file, 
          PDKSYNC_FILE_NAME, 
          File.join(ENV['HOME'], PDKSYNC_FILE_NAME)
      ]
      files.find do |file|
        next unless file
        File.exist?(file)
      end
    end

    private

    # @return [Boolean] true if the supported platforms were specified correctly
    # @param scm [Symbol] - the scm type (:github or :gitlab)
    def valid_scm?(scm)
      unless SUPPORTED_SCM_PLATFORMS.include?(git_platform)
        raise ArgumentError, "Unsupported Git hosting platform '#{git_platform}'."\
          " Supported platforms are: #{SUPPORTED_SCM_PLATFORMS.join(', ')}"
      end
      true
    end

    # @return [Boolean] true if the access token for the scm platform was supplied
    def valid_access_token?
      if access_token.nil?
        raise ArgumentError, "Git platform access token for #{git_platform.capitalize} not set"\
          " - use 'export #{git_platform.upcase}_TOKEN=\"<your token>\"' to set"
      end
      true
    end

    # @return [String] the platform specific access token
    def access_token
      case git_platform
      when :github
        ENV['GITHUB_TOKEN'].freeze
      when :gitlab
        ENV['GITLAB_TOKEN'].freeze
      end
    end
  end
end

# monkey patch 
class Hash
  #take keys of hash and transform those to a symbols
  def transform_keys_to_symbols
    self.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
  end
end