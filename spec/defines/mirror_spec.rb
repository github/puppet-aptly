require 'spec_helper'

describe 'aptly::mirror' do
  let(:title) { 'example' }
  let(:facts) {{
    :lsbdistid       => 'Debian',
    :lsbdistcodename => 'precise',
    :osfamily        => 'Debian',
  }}

  describe 'param defaults and mandatory' do
    let(:params) {{
      :location => 'http://repo.example.com',
      :key      => 'ABC123',
    }}

    it {
      should contain_exec('aptly_mirror_gpg-example').with({
        :command => / --keyserver 'keyserver.ubuntu.com' --recv-keys 'ABC123'$/,
        :unless  => /^echo 'ABC123' |/,
        :user    => 'root',
      })
    }

    it {
      should contain_exec('aptly_mirror_create-example').with({
        :command => /aptly mirror create -with-sources=false -with-udebs=false -force-components=false example http:\/\/repo\.example\.com precise$/,
        :unless  => /aptly mirror show example >\/dev\/null$/,
        :user    => 'root',
        :require => [
          'Package[aptly]',
          'Exec[aptly_mirror_gpg-example]'
        ],
      })
    }

    context 'two repos with same key' do
      let(:pre_condition) { <<-EOS
        aptly::mirror { 'example-lucid':
          location => 'http://lucid.example.com/',
          key      => 'ABC123',
        }
        EOS
      }

      it { should contain_exec('aptly_mirror_gpg-example-lucid') }
    end
  end

  describe '#user' do
    context 'with custom user' do
      let(:pre_condition)  { <<-EOS
        class { 'aptly':
          user => 'custom_user',
        }
        EOS
      }

      let(:params){{
        :location => 'http://repo.example.com',
        :key      => 'ABC123',
      }}

      it {
        should contain_exec('aptly_mirror_gpg-example').with({
          :command => / --keyserver 'keyserver.ubuntu.com' --recv-keys 'ABC123'$/,
          :unless  => /^echo 'ABC123' |/,
          :user    => 'custom_user',
        })
      }

      it {
        should contain_exec('aptly_mirror_create-example').with({
          :command => /aptly mirror create -with-sources=false -with-udebs=false -force-components=false example http:\/\/repo\.example\.com precise$/,
          :unless  => /aptly mirror show example >\/dev\/null$/,
          :user    => 'custom_user',
          :require => [
            'Package[aptly]',
            'Exec[aptly_mirror_gpg-example]'
          ],
        })
      }
    end
  end

  describe '#keyserver' do
    context 'with custom keyserver' do
      let(:params){{
        :location   => 'http://repo.example.com',
        :key        => 'ABC123',
        :keyserver  => 'hkp://repo.keyserver.com:80',
      }}

      it{
        should contain_exec('aptly_mirror_gpg-example').with({
          :command => / --keyserver 'hkp:\/\/repo.keyserver.com:80' --recv-keys 'ABC123'$/,
          :unless  => /^echo 'ABC123' |/,
          :user    => 'root',
        })
      }
    end
  end

  describe '#environment' do
    context 'not an array' do
      let(:params){{
        :location    => 'http://repo.example.com',
        :key         => 'ABC123',
        :environment => 'FOO=bar',
      }}

      it {
        should raise_error(Puppet::Error, /is not an Array/)
      }
    end

    context 'defaults to empty array' do
      let(:params){{
        :location    => 'http://repo.example.com',
        :key         => 'ABC123',
      }}

      it {
        should contain_exec('aptly_mirror_create-example').with({
          :environment => [],
        })
      }
    end

    context 'with FOO set to bar' do
      let(:params){{
        :location    => 'http://repo.example.com',
        :key         => [ 'ABC123' ],
        :environment => ['FOO=bar'],
      }}

      it{
        should contain_exec('aptly_mirror_create-example').with({
          :environment => ['FOO=bar'],
        })
      }
    end
  end

  describe '#key' do
    context 'single item not in an array' do
      let(:params){{
        :location   => 'http://repo.example.com',
        :key        => 'ABC123',
      }}

      it{
        should contain_exec('aptly_mirror_gpg-example').with({
          :command => / --keyserver 'keyserver.ubuntu.com' --recv-keys 'ABC123'$/,
          :unless  => /^echo 'ABC123' |/,
        })
      }
    end

    context 'single item in an array' do
      let(:params){{
        :location   => 'http://repo.example.com',
        :key        => [ 'ABC123' ],
      }}

      it{
        should contain_exec('aptly_mirror_gpg-example').with({
          :command => / --keyserver 'keyserver.ubuntu.com' --recv-keys 'ABC123'$/,
          :unless  => /^echo 'ABC123' |/,
        })
      }
    end

    context 'multiple items' do
      let(:params){{
        :location   => 'http://repo.example.com',
        :key        => [ 'ABC123', 'DEF456', 'GHI789' ],
      }}

      it{
        should contain_exec('aptly_mirror_gpg-example').with({
          :command => / --keyserver 'keyserver.ubuntu.com' --recv-keys 'ABC123' 'DEF456' 'GHI789'$/,
          :unless  => /^echo 'ABC123' 'DEF456' 'GHI789' |/,
        })
      }
    end

    context 'no key passed' do
      let(:params) {
        {
          :location => 'http://repo.example.com',
        }
      }

      it {
        should_not contain_exec('aptly_mirror_gpg-example')
      }
    end
  end

  describe '#repos' do
    context 'not an array' do
      let(:params) {{
        :location => 'http://repo.example.com',
        :key      => 'ABC123',
        :repos    => 'this is a string',
      }}

      it {
        should raise_error(Puppet::Error, /is not an Array/)
      }
    end

    context 'single item' do
      let(:params) {{
        :location => 'http://repo.example.com',
        :key      => 'ABC123',
        :repos    => ['main'],
      }}

      it {
        should contain_exec('aptly_mirror_create-example').with_command(
          /aptly mirror create -with-sources=false -with-udebs=false -force-components=false example http:\/\/repo\.example\.com precise main$/
        )
      }
    end

    context 'multiple items' do
      let(:params) {{
        :location => 'http://repo.example.com',
        :key      => 'ABC123',
        :repos    => ['main', 'contrib', 'non-free'],
      }}

      it {
        should contain_exec('aptly_mirror_create-example').with_command(
          /aptly mirror create -with-sources=false -with-udebs=false -force-components=false example http:\/\/repo\.example\.com precise main contrib non-free$/
        )
      }
    end
  end

  describe '#cli_options' do
    context 'not a hash' do
      let(:params) {{
        :location    => 'http://repo.example.com',
        :key         => 'ABC123',
        :cli_options => 'this is a string',
      }}

      it {
        should raise_error(Puppet::Error, /is not a Hash/)
      }
    end

    context 'with valid options' do
      let(:params) {{
        :location    => 'http://repo.example.com',
        :key         => 'ABC123',
        :cli_options => {
          '-with-sources'     => false,
          '-with-udebs'       => false,
          '-force-components' => false,
        }
      }}

      it {
        should contain_exec('aptly_mirror_create-example').with_command(
          /aptly mirror create -with-sources=false -with-udebs=false -force-components=false example http:\/\/repo\.example\.com precise$/
        )
      }
    end

    context 'default options' do
      let(:params) {{
        :location    => 'http://repo.example.com',
        :key         => 'ABC123',
        :cli_options => {}
      }}

      it {
        should contain_exec('aptly_mirror_create-example').with_command(
          /aptly mirror create -with-sources=false -with-udebs=false -force-components=false example http:\/\/repo\.example\.com precise$/
        )
      }
    end

    context 'overriding options' do
      let(:params) {{
        :location    => 'http://repo.example.com',
        :key         => 'ABC123',
        :cli_options => {
          '-force-components' => true,
        }
      }}

      it {
        should contain_exec('aptly_mirror_create-example').with_command(
          /aptly mirror create -with-sources=false -with-udebs=false -force-components=true example http:\/\/repo\.example\.com precise$/
        )
      }
    end
  end

  describe 'user defined configuration' do
    let(:params){{
      :location => 'http://repo.example.com',
      :key      => 'ABC123',
      :cli_options => {
        '-config' => '/tmp/aptly.conf'
      }
    }}

    it {
      should contain_exec('aptly_mirror_create-example').with({
        :command => /aptly mirror create -with-sources=false -with-udebs=false -force-components=false -config=\/tmp\/aptly.conf example http:\/\/repo\.example\.com precise$/,
        :unless  => /aptly mirror show -config=\/tmp\/aptly.conf example >\/dev\/null$/,
        :user    => 'root',
        :require => [
          'Package[aptly]',
          'Exec[aptly_mirror_gpg-example]'
        ],
      })
    }
  end
end
