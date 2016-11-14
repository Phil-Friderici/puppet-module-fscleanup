require 'spec_helper'
describe 'fscleanup' do
  let(:facts) do
    {
      :operatingsystem        => 'SLES',
      :operatingsystemrelease => '11.4',
      :systemd                => nil,
    }
  end

  context 'with default params on operatingsystem running systemd' do
    let(:facts) do
      {
        :operatingsystem        => 'RedHat',
        :operatingsystemrelease => '7.3',
        :systemd                => true,
      }
    end
    it { should compile.with_all_deps }
    it { should contain_class('fscleanup') }

    # systemd specific resources
    content = <<-END.gsub(/^\s+\|/, '')
      |# This file is being maintained by Puppet.
      |# DO NOT EDIT
      |
      |#  This file is part of systemd.
      |#
      |#  systemd is free software; you can redistribute it and/or modify it
      |#  under the terms of the GNU Lesser General Public License as published by
      |#  the Free Software Foundation; either version 2.1 of the License, or
      |#  (at your option) any later version.
      |
      |# See tmpfiles.d(5) for details
      |
      |# Puppet: use only the base types d,D,x,X,r,R
      |
      |# Clear tmp directories separately, to make them easier to override
      |# Puppet: clean if mtime and ctime and atime exceed 7 or 21 days
      |d /tmp 1777 root root 7d
      |d /var/tmp 1777 root root 21d
      |
      |# Puppet: do not clean files from these owners
      |x /tmp - - - - root,nobody
      |x /var/tmp - - - - root,nobody
      |
      |
      |# Exclude namespace mountpoints created with PrivateTmp=yes
      |x /tmp/systemd-private-%b-*
      |X /tmp/systemd-private-%b-*/tmp
      |x /var/tmp/systemd-private-%b-*
      |X /var/tmp/systemd-private-%b-*/tmp
    END

    it do
      should contain_file('/etc/tmpfiles.d/tmp.conf').with({
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
        'content' => content,
      })
    end

    # SLED/SLES 11 specific resources
    it { should_not contain_file('/usr/local/etc') }
    it { should_not contain_file('/usr/local/etc/fscleanup.conf') }
    it { should_not contain_file('/usr/local/bin/fscleanup.sh') }
    it { should_not contain_file('/etc/cron.daily/suse.de-clean-tmp') }
    it { should_not contain_cron('fscleanup.sh') }
    it { should_not contain_file('/etc/init.d/boot.cleanup') }

    # ramdisk specifc resources
    it { should_not contain_file('/usr/local/bin/ramdisk_cleanup.sh') }
    it { should_not contain_cron('ramdisk_cleanup.sh') }

    context 'when clear_at_boot set to valid true' do
      let(:params) { { :clear_at_boot => true } }
      it { should contain_file('/etc/tmpfiles.d/tmp.conf').with_content(%r{^R! /tmp/\*$}) }
    end

    context 'with tmp_long_dirs set to valid array %w(/tmp /var/tmp)' do
      let(:params) { { :tmp_long_dirs => %w(/tmp /var/tmp) } }
      it { should contain_file('/etc/tmpfiles.d/tmp.conf').with_content(%r{^d /tmp 1777 root root 21d\nd /var/tmp 1777 root root 21d$}) }
    end

    context 'with tmp_long_max_days set to valid 242' do
      let(:params) { { :tmp_long_max_days => 242 } }
      it { should contain_file('/etc/tmpfiles.d/tmp.conf').with_content(%r{^d /var/tmp 1777 root root 242d$}) }
    end

    context 'with tmp_owners_to_keep set to valid array %w(spec tests kicks)' do
      let(:params) { { :tmp_owners_to_keep => %w(spec tests kicks) } }
      it { should contain_file('/etc/tmpfiles.d/tmp.conf').with_content(%r{^x /tmp - - - - spec,tests,kicks\nx /var/tmp - - - - spec,tests,kicks$}) }
    end

    context 'with tmp_short_dirs set to valid array %w(/tmp /local/scratch)' do
      let(:params) { { :tmp_short_dirs => %w(/tmp /local/scratch) } }
      it { should contain_file('/etc/tmpfiles.d/tmp.conf').with_content(%r{^d /tmp 1777 root root 7d\nd /local/scratch 1777 root root 7d$}) }
    end

    context 'with tmp_short_max_days set to valid 242' do
      let(:params) { { :tmp_short_max_days => 242 } }
      it { should contain_file('/etc/tmpfiles.d/tmp.conf').with_content(%r{^d /tmp 1777 root root 242d$}) }
    end
  end

  context 'with default params on operatingsystem SLES 11.4 running init' do
    it { should compile.with_all_deps }
    it { should contain_class('fscleanup') }

    # systemd specific resources
    it { should_not contain_cron('/etc/tmpfiles.d/tmp.conf') }

    # SLED/SLES 11 specific resources
    it do
      should contain_file('/usr/local/etc').with({
        'ensure' => 'directory',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0755',
      })
    end

    it do
      should contain_file('/usr/local/etc/fscleanup.conf').with({
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
        'require' => 'File[/usr/local/etc]',
        'content' => File.read(fixtures('fscleanup.conf.default'))
      })
    end

    it do
      should contain_file('/usr/local/bin/fscleanup.sh').with({
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0755',
        'require' => 'File[/usr/local/etc/fscleanup.conf]',
        'source'  => 'puppet:///modules/fscleanup/fscleanup.sh',
      })
    end

    it do
      should contain_file('/etc/cron.daily/suse.de-clean-tmp').with({
        'ensure'  => 'absent',
      })
    end

    it do
      should contain_cron('fscleanup.sh').with({
        'command' => '/usr/local/bin/fscleanup.sh >/dev/null 2>&1',
        'hour'    => '06',
        'minute'  => '00',
        'require' => 'File[/usr/local/bin/fscleanup.sh]',
      })
    end

    it do
      should contain_file('/etc/init.d/boot.cleanup').with({
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0755',
        'content' => File.read(fixtures('boot.cleanup.default'))
      })
    end

    # ramdisk specifc resources
    it { should_not contain_file('/usr/local/bin/ramdisk_cleanup.sh') }
    it { should_not contain_cron('ramdisk_cleanup.sh') }

    context 'when clear_at_boot set to valid true' do
      let(:params) { { :clear_at_boot => true } }
      it { should contain_file('/usr/local/etc/fscleanup.conf').with_content(/^CLEAR_TMP_DIRS_AT_BOOTUP="yes"$/) }
    end

    context 'with tmp_long_dirs set to valid array %w(/tmp /var/tmp)' do
      let(:params) { { :tmp_long_dirs => %w(/tmp /var/tmp) } }
      it { should contain_file('/usr/local/etc/fscleanup.conf').with_content(%r{^LONG_TMP_DIRS_TO_CLEAR="/tmp /var/tmp"$}) }
    end

    context 'with tmp_long_max_days set to valid 242' do
      let(:params) { { :tmp_long_max_days => 242 } }
      it { should contain_file('/usr/local/etc/fscleanup.conf').with_content(/^MAX_DAYS_IN_LONG_TMP="242"$/) }
    end

    context 'with tmp_owners_to_keep set to valid array %w(spec tests kicks)' do
      let(:params) { { :tmp_owners_to_keep => %w(spec tests kicks) } }
      it { should contain_file('/usr/local/etc/fscleanup.conf').with_content(/^OWNER_TO_KEEP_IN_TMP="spec tests kicks"$/) }
    end

    context 'with tmp_short_dirs set to valid array %w(/tmp /local/scratch)' do
      let(:params) { { :tmp_short_dirs => %w(/tmp /local/scratch) } }
      it { should contain_file('/usr/local/etc/fscleanup.conf').with_content(%r{^TMP_DIRS_TO_CLEAR="/tmp /local/scratch"$}) }
    end

    context 'with tmp_short_max_days set to valid 242' do
      let(:params) { { :tmp_short_max_days => 242 } }
      it { should contain_file('/usr/local/etc/fscleanup.conf').with_content(/^MAX_DAYS_IN_TMP="242"$/) }
    end
  end

  context 'with default params on operatingsystem running init' do
    let(:facts) do
      {
        :operatingsystem        => 'RedHat',
        :operatingsystemrelease => '6.8',
        :systemd                => nil,
      }
    end
    it 'should fail' do
      expect { should contain_class(subject) }.to raise_error(Puppet::Error, %r{fscleanup::tmp_cleanup is only supported on SLED/SLES 11 and OSfamilies using systemd})
    end
  end

  context 'with tmp_cleanup set to valid false' do
    let(:params) { { :tmp_cleanup => false } }
    it { should have_file_resource_count(0) }
    it { should have_cron_resource_count(0) }
  end

  context 'with ramdisk_cleanup set to valid true' do
    context 'when ramdisk_dir left unset' do
      let(:params) { { :ramdisk_cleanup => true } }
      it 'should fail' do
        expect { should contain_class(subject) }.to raise_error(Puppet::Error, /is not an absolute path/)
      end
    end

    context 'when ramdisk_dir is set to valid /ramdisk' do
      let(:params) do
        {
          :ramdisk_cleanup => true,
          :ramdisk_dir     => '/ramdisk',
        }
      end

      it do
        should contain_file('/usr/local/bin/ramdisk_cleanup.sh').with({
          'ensure'  => 'file',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755',
          'content' => File.read(fixtures('ramdisk_cleanup.sh.default'))
        })
      end

      it do
        should contain_cron('ramdisk_cleanup.sh').with({
          'command' => '/usr/local/bin/ramdisk_cleanup.sh 21 d',
          'hour'    => '15',
          'minute'  => '30',
          'require' => 'File[/usr/local/bin/ramdisk_cleanup.sh]',
        })
      end
    end

    context 'when ramdisk_mail is set to valid false' do
      let(:params) do
        {
          :ramdisk_cleanup => true,
          :ramdisk_dir     => '/ramdisk',
          :ramdisk_mail    => false,
        }
      end
      it { should contain_file('/usr/local/bin/ramdisk_cleanup.sh').with_content(/^unset message$/) }
    end

    context 'when and ramdisk_max_days is set to valid 242' do
      let(:params) do
        {
          :ramdisk_cleanup  => true,
          :ramdisk_dir      => '/ramdisk',
          :ramdisk_max_days => 242,
        }
      end
      it do
        should contain_cron('ramdisk_cleanup.sh').with({
          'command' => '/usr/local/bin/ramdisk_cleanup.sh 242 d',
          'hour'    => '15',
          'minute'  => '30',
          'require' => 'File[/usr/local/bin/ramdisk_cleanup.sh]',
        })
      end
    end
  end

  describe 'variable type and content validations' do
    let(:mandatory_params) { {} }

    validations = {
      'absolute_path' => {
        :name    => %w(tmp_short_dirs tmp_long_dirs),
        :valid   => ['/absolute/filepath', '/absolute/directory/', %w(/array /with_paths)],
        :invalid => ['../invalid', 3, 2.42, %w(array), { 'ha' => 'sh' }, true, false, nil],
        :message => 'is not an absolute path',
      },
      'absolute_path_ramdisk_dir' => {
        :name    => %w(ramdisk_dir),
        :params  => { :ramdisk_cleanup => true },
        :valid   => ['/absolute/filepath', '/absolute/directory/', %w(/array /with_paths)],
        :invalid => ['../invalid', 3, 2.42, %w(array), { 'ha' => 'sh' }, true, false, nil],
        :message => 'is not an absolute path',
      },
      'array/string' => {
        :name    => %w(tmp_owners_to_keep),
        :valid   => [%w(ar ray), 'string'],
        :invalid => [{ 'ha' => 'sh' }, 3, 2.42, true, false],
        :message => 'is not an array nor a string',
      },
      'bool_stringified' => {
        :name    => %w(clear_at_boot tmp_cleanup ramdisk_cleanup ramdisk_mail),
        :params  => { :ramdisk_dir => '/ramdisk' },
        :valid   => [true, false, 'true', 'false'],
        :invalid => ['invalid', %w(array), { 'ha' => 'sh' }, 3, 2.42, nil],
        :message => '(Unknown type of boolean|str2bool\(\): Requires either string to work with)',
      },
      'integer_stringified' => {
        :name    => %w(tmp_short_max_days tmp_long_max_days ramdisk_max_days),
        :valid   => [242, '242', -242, '-242', 2.42],
        :invalid => ['invalid', %w(array), { 'ha' => 'sh' }, true, false, nil],
        :message => 'floor\(\): Wrong argument type given',
      },

    }

    validations.sort.each do |type, var|
      var[:name].each do |var_name|
        var[:params] = {} if var[:params].nil?
        var[:valid].each do |valid|
          context "when #{var_name} (#{type}) is set to valid #{valid} (as #{valid.class})" do
            let(:params) { [mandatory_params, var[:params], { :"#{var_name}" => valid, }].reduce(:merge) }
            it { should compile }
          end
        end

        var[:invalid].each do |invalid|
          context "when #{var_name} (#{type}) is set to invalid #{invalid} (as #{invalid.class})" do
            let(:params) { [mandatory_params, var[:params], { :"#{var_name}" => invalid, }].reduce(:merge) }
            it 'should fail' do
              expect { should contain_class(subject) }.to raise_error(Puppet::Error, /#{var[:message]}/)
            end
          end
        end
      end # var[:name].each
    end # validations.sort.each
  end # describe 'variable type and content validations'
end
