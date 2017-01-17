require 'spec_helper'

describe 'aptly::repo' do
  let(:title) { 'example' }

  let(:facts){{
    :lsbdistid => 'ubuntu',
    :osfamily  => 'Debian',
  }}

  describe 'param defaults' do
    it {
        should contain_exec('aptly_repo_create-example').with({
          :command  => /aptly repo create *example$/,
          :unless   => /aptly repo show example >\/dev\/null$/,
          :user     => 'root',
          :require  => 'Package[aptly]',
      })
    }
  end

  describe 'user defined component' do
    let(:params){{
      :cli_options => {
        '-component' => 'third-party'
      }
    }}

    it {
        should contain_exec('aptly_repo_create-example').with({
          :command  => /aptly repo create *-component=third-party *example$/,
          :unless   => /aptly repo show example >\/dev\/null$/,
          :user     => 'root',
          :require  => 'Package[aptly]',
      })
    }

    context 'custom user' do
      let(:pre_condition)  { <<-EOS
        class { 'aptly':
          user => 'custom_user',
        }
        EOS
      }

      let(:params){{
        :cli_options => {
          '-component' => 'third-party'
        }
      }}

      it {
          should contain_exec('aptly_repo_create-example').with({
            :command  => /aptly repo create *-component=third-party *example$/,
            :unless   => /aptly repo show example >\/dev\/null$/,
            :user     => 'custom_user',
            :require  => 'Package[aptly]',
        })
      }
    end
  end

  describe 'user defined architectures' do
    context 'passing valid values' do
      let(:params){{
        :cli_options => {
          '-architectures' => 'i386,amd64',
        }
      }}

      it {
        should contain_exec('aptly_repo_create-example').with({
          :command  => /aptly repo create *-architectures=i386,amd64 *example$/,
          :unless   => /aptly repo show example >\/dev\/null$/,
          :user     => 'root',
          :require  => 'Package[aptly]',
        })
      }
    end
  end

  describe 'user defined comment' do
    let(:params){{
      :cli_options => {
        '-comment' => 'example comment'
      }
    }}

    it {
      should contain_exec('aptly_repo_create-example').with({
        :command  => /aptly repo create *-comment=example comment *example$/,
        :unless   => /aptly repo show example >\/dev\/null$/,
        :user     => 'root',
        :require  => 'Package[aptly]',
      })
    }
  end

  describe 'user defined distribution' do
    let(:params){{
      :cli_options => {
        '-distribution' => 'example_distribution'
      }
    }}

    it {
      should contain_exec('aptly_repo_create-example').with({
        :command  => /aptly repo create *-distribution=example_distribution *example$/,
        :unless   => /aptly repo show example >\/dev\/null$/,
        :user     => 'root',
        :require  => 'Package[aptly]',
      })
    }
  end

end
