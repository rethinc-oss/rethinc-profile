require 'spec_helper'

describe 'profile::server::bootstrap' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to contain_file('/var/cache/apt/.intial_update_done').with(
        'ensure' -> 'present',
      ) }
    end
  end
end
