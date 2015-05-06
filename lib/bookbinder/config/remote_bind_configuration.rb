require 'yaml'
require_relative '../ingest/destination_directory'

module Bookbinder
  module Config
    class RemoteBindConfiguration
      VersionUnsupportedError = Class.new(RuntimeError)

      def initialize(logger, version_control_system, base_config)
        @logger = logger
        @version_control_system = version_control_system
        @base_config = base_config
      end

      def to_h
        sections = base_config.sections
        base = {
          sections: sections,
          book_repo: base_config.book_repo,
          host_for_sitemap: base_config.public_host,
          archive_menu: base_config.archive_menu,
          versions: base_config.versions,
          template_variables: base_config.template_variables
        }
        base_config.versions.each { |version| sections.concat(sections_from(version)) }
        base
      end

      private

      attr_reader :logger, :version_control_system, :base_config

      def sections_from(version)
        attrs = YAML.load(
          version_control_system.read_file(
            'config.yml',
            from_repo: "git@github.com:#{base_config.book_repo}",
            checkout: version
          )
        )['sections']
        raise VersionUnsupportedError.new(version) if attrs.nil?

        attrs.map do |section_hash|
          section_hash['repository']['ref'] = version
          section_hash['directory'] = File.join(version, section_hash['directory'])
          section_hash
        end
      end
    end
  end
end
