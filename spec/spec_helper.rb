require 'rspec'

def fixtures_dir
  @fixtures_dir ||= File.join(__dir__, 'fixtures')
end