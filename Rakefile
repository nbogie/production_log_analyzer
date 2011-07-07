ENV.delete 'GEM_PATH'

require 'rubygems'
require 'hoe'

Hoe.plugin :email, :perforce # not on minitest yet

Hoe.spec 'nbogie-production_log_analyzer' do
  developer 'Eric Hodel', 'drbrain@segment7.net'
  self.name = 'nbogie-production_log_analyzer'
  self.version = '1.5.1.2'

  extra_deps << ['rails_analyzer_tools', '>= 1.4.0']
end
