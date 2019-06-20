require 'shellwords'

module Danger
  # Run Ruby files through Brakeman.
  # Results are passed out as a table in markdown.
  #
  # @example Lint changed files
  #
  #          brakeman.lint
  #
  class DangerBrakeman < Plugin
    # Runs Ruby files through Brakeman. Generates a `markdown` list of warnings.
    def lint(config = nil)
      files_to_lint = _fetch_files_to_lint
      brakeman_result = _brakeman(files_to_lint)

      return if brakeman_result.nil?

      _add_warning_for_each_line(brakeman_result)
    end

    private

    def _brakeman(files_to_lint)
      base_command = 'brakeman -q -f json --only-files'

      brakeman_output = `#{'bundle exec ' if File.exist?('Gemfile')}#{base_command} #{files_to_lint}`

      return [] if brakeman_output.empty?

      JSON.parse(brakeman_output)['warnings']
    end

    def _add_warning_for_each_line(brakeman_result)
      brakeman_result.each do |warning|
        arguments = [
          "[brakeman] #{warning['message']}",
          {
            file: warning['file'],
            line: warning['line']
          }
        ]
        warn(*arguments)
      end
    end

    def _fetch_files_to_lint
      to_lint = git.modified_files + git.added_files
      Shellwords.join(to_lint).gsub(" ", ",")
    end
  end
end
