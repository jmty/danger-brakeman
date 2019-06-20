require File.expand_path("../spec_helper", __FILE__)

module Danger
  describe Danger::DangerBrakeman do
    it "should be a plugin" do
      expect(Danger::DangerBrakeman.new(nil)).to be_a Danger::Plugin
    end

    describe "with Dangerfile" do
      before do
        @brakeman = testing_dangerfile.brakeman
      end

      describe :lint_files do
        let(:response_lint) do
          {
            'warnings': [
              {
                'warning_type': "Remote Code Execution",
                'warning_code': 24,
                'fingerprint': "xxxx",
                'check_name': "UnsafeReflection",
                'message': "Unsafe reflection method `constantize` called with parameter value",
                'file': "app/controllers/vuls_controller.rb",
                'line': 45,
                'link': "https://brakemanscanner.org/docs/warning_types/remote_code_execution/",
                'code': "xxxx",
                'render_path': nil,
                'location': {
                  'type': "method",
                  'class': "VulsController",
                  'method': "create"
                },
                'user_input': "params[:to]",
                'confidence': "Medium"
              },
              {
                'warning_type': "Cross-Site Request Forgery",
                'warning_code': 7,
                'fingerprint': "yyyy",
                'check_name': "ForgerySetting",
                'message': "`protect_from_forgery` should be called in `VulsController`",
                'file': "app/vuls_controller.rb",
                'line': 1,
                'link': "https://brakemanscanner.org/docs/warning_types/cross-site_request_forgery/",
                'code': nil,
                'render_path': nil,
                'location': {
                  'type': "controller",
                  'controller': "VulsController"
                },
                'user_input': nil,
                'confidence': "High"
              }
            ]
          }.to_json
        end

        it 'handles a brakeman report for files changed in the PR' do
          allow(@brakeman.git).to receive(:added_files).and_return([])
          allow(@brakeman.git).to receive(:modified_files)
                                   .and_return(["spec/fixtures/check_target_file.rb"])

          allow(@brakeman).to receive(:`)
                               .with('bundle exec brakeman -q -f json --only-files spec/fixtures/check_target_file.rb')
                               .and_return(response_lint)

          @brakeman.lint

          outputs = @brakeman.violation_report[:warnings].map(&:to_s)

          expect(outputs.first).to include('Violation [brakeman] Unsafe reflection method `constantize` called with parameter value { sticky: false, file: app/controllers/vuls_controller.rb, line: 45 }')
          expect(outputs.last).to  include('Violation [brakeman] `protect_from_forgery` should be called in `VulsController` { sticky: false, file: app/vuls_controller.rb, line: 1 }')
        end
      end
    end
  end
end
