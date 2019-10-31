require 'spec_helper'
require 'pdksync/puppet_module'

describe 'PdkSync::PuppetModule' do
  before(:each) do
    allow(ENV).to receive(:[]).with('HOME').and_return('./')
    allow(ENV).to receive(:[]).with('GIT_DIR').and_return(nil)
    allow(ENV).to receive(:[]).with('GIT_WORK_TREE').and_return(nil)
    allow(ENV).to receive(:[]).with('GIT_INDEX_FILE').and_return(nil)
    allow(ENV).to receive(:[]).with('PDKSYNC_LOG_FILENAME').and_return(nil)
    allow(ENV).to receive(:[]).with('LOG_LEVEL').and_return(nil)
    allow(ENV).to receive(:[]).with('GIT_SSH').and_return(nil)
    allow(ENV).to receive(:[]).with('GITHUB_TOKEN').and_return('blah')
    allow(ENV).to receive(:[]).with('PDKSYNC_VERSION_CHECK').and_return(nil)
    allow(ENV).to receive(:[]).with('http_proxy').and_return(nil)
    allow(ENV).to receive(:[]).with('HTTP_PROXY').and_return(nil)
    allow(ENV).to receive(:[]).with('PDKSYNC_CONFIG_PATH').and_return(nil)
    allow(PdkSync::Utils).to receive(:return_modules).and_return(@module_names)
    allow(PdkSync::Utils).to receive(:validate_modules_exist).and_return(@module_names)
    allow(PdkSync::Utils).to receive(:setup_client).and_return(git_client)

    Dir.chdir(@folder)
  end

  let(:mod) do
    PdkSync::PuppetModule.new('puppet', module_name, output_path)
  end

  let(:git_client) do
    double(PdkSync::GitPlatformClient)
  end

  let(:output_path) do
    File.join('./modules_pdksync', module_name)
  end

  let(:module_name) do
    'puppetlabs-testing'
  end

  before(:all) do
    @module_names = ['puppetlabs-testing']
    @folder = Dir.pwd
  end

  it '#new' do
    expect(mod).to be_a PdkSync::PuppetModule
  end

  it '#ensure_present' do
    expect(mod).to transition_from(:absent).to(:latest).on_event(:ensure_present)
  end

  it '#ensure_latest' do
    expect(mod).to transition_from(:absent).to(:latest).on_event(:ensure_latest)
  end

  it '#commit_code' do
    expect(mod).to transition_from(:present).to(:commmited).on_event(:commit_code, git_repo, template_ref, 'commit_message')
  end
end
