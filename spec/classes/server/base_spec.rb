require 'spec_helper'

describe 'profile::server::base' do
  let(:params) do
    {
      'management_user_password' => 'sysop',
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge({
          'apt_update_last_success' => -1,
        })
      end

      it { is_expected.to compile }

      #
      # Test system management user
      #
      context 'management-user with default values' do
        it {
          is_expected.to contain_user('sysop').with({
            'comment'    => 'System Operator',
            'managehome' => true,
            'groups'     => ['adm', 'sudo', 'operator']
          })
        }
      end

      context 'management-user with custom values' do
        let(:params) do
          super().merge({
            'management_user_login' => 'foobar',
            'management_user_name' => 'Almighty',
          })
        end
        it {
          is_expected.to contain_user('foobar').with({
            'comment'    => 'Almighty',
            'managehome' => true,
          })
        }
      end

      context 'management-user with public key' do
        let(:params) do
          super().merge({
            'management_user_public_keys' => ['alice@example.com'],
            'public_key_definitions' => {
              'alice@example.com' => {
                'type'    => 'ssh-ed25519',
                'key'     => 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
                'comment' => 'Alice (Login Key)',
              },
              'bob@example.com' => {
                'type'    => 'ssh-ed25519',
                'key'     => 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
                'comment' => 'Bob (Login Key)',
              },
            }
          })
        end
        it {
          is_expected.to contain_user('sysop').with({
            'comment'    => 'System Operator',
            'managehome' => true,
          })
          is_expected.to contain_ssh_authorized_key('sysop(alice@example.com)').with({
            'type' => 'ssh-ed25519',
            'key'  => 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
            'name' => 'Alice (Login Key)',
          })
        }
      end

      context 'management-user with missing public key' do
        let(:params) do
          super().merge({
            'management_user_public_keys' => ['alice@example.com'],
          })
        end

        it { is_expected.to compile.and_raise_error(/Key for alice@example.com not found!/) }
      end

      it { is_expected.to contain_file('/etc/nanorc').with({
        'ensure' => 'present',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0444',})
      }
    end
  end
end
