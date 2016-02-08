require 'spec_helper'
describe 'fscleanup' do
  let(:facts) do
    {
      :operatingsystem        => 'SLES',
      :operatingsystemrelease => '11.4',
    }
  end

  context 'with default params on fully supported operatingsystem SLES 11.4' do
    it { should compile.with_all_deps }
    it { should contain_class('fscleanup')}

    # SLED/SLES 11 specifics
    it {
      should contain_file('/usr/local/etc').with({
        'ensure' => 'directory',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0755',
      })
    }

    it {
      should contain_file('/usr/local/etc/fscleanup.conf').with({
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
        'require' => 'File[/usr/local/etc]',
        'content' => File.read(fixtures('fscleanup.conf.default'))
      })
    }

    it {
      should contain_file('/usr/local/bin/fscleanup.sh').with({
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0755',
        'require' => 'File[/usr/local/etc/fscleanup.conf]',
        'content' => File.read(fixtures('fscleanup.sh'))
      })
    }

    it {
      should contain_file('/etc/cron.daily/suse.de-clean-tmp').with({
        'ensure'  => 'absent',
      })
    }

    it {
      should contain_cron('fscleanup.sh').with({
        'command' => '/usr/local/bin/fscleanup.sh >/dev/null 2>&1',
        'hour'    => '06',
        'minute'  => '00',
        'require' => 'File[/usr/local/bin/fscleanup.sh]',
      })
    }

    it {
      should contain_file('/etc/init.d/boot.cleanup').with({
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0755',
        'content' => File.read(fixtures('boot.cleanup.default'))
      })
    }

    # ramdisk specifcs
    it { should_not contain_file('/usr/local/bin/ramdisk_cleanup.sh') }
    it { should_not contain_cron('ramdisk_cleanup.sh') }
  end

  context 'with clear_at_boot set to valid true' do
    let (:params) { { :clear_at_boot => true } }
    it { should contain_file('/usr/local/etc/fscleanup.conf').with_content(/^CLEAR_TMP_DIRS_AT_BOOTUP="yes"$/) }
  end

  context 'with tmp_cleanup set to valid false' do
    let (:params) { { :tmp_cleanup => false } }
    it { should have_file_resource_count(0) }
    it { should have_cron_resource_count(0) }
  end

  context 'with tmp_short_dirs set to valid array %w(/tmp /local/scratch)' do
    let (:params) { { :tmp_short_dirs => %w(/tmp /local/scratch) } }
    it { should contain_file('/usr/local/etc/fscleanup.conf').with_content(%r{^TMP_DIRS_TO_CLEAR="/tmp /local/scratch"$}) }
  end

  context 'with tmp_short_max_days set to valid 242' do
    let (:params) { { :tmp_short_max_days => 242 } }
    it { should contain_file('/usr/local/etc/fscleanup.conf').with_content(%r{^MAX_DAYS_IN_TMP="242"$}) }
  end

  context 'with tmp_owners_to_keep set to valid array %w(spec tests kicks)' do
    let (:params) { { :tmp_owners_to_keep => %w(spec tests kicks) } }
    it { should contain_file('/usr/local/etc/fscleanup.conf').with_content(%r{^OWNER_TO_KEEP_IN_TMP="spec tests kicks"$}) }
  end

  context 'with tmp_long_max_days set to valid 242' do
    let (:params) { { :tmp_long_max_days => 242 } }
    it { should contain_file('/usr/local/etc/fscleanup.conf').with_content(%r{^MAX_DAYS_IN_LONG_TMP="242"$}) }
  end

  context 'with ramdisk_cleanup set to valid true' do
    context 'and ramdisk_dir left unset' do
      let (:params) { { :ramdisk_cleanup => true } }
      it 'should fail' do
        expect { should contain_class(subject) }.to raise_error(Puppet::Error, /is not an absolute path/)
      end
    end

    context 'and ramdisk_dir is set to valid /ramdisk' do
      let(:params) do
        {
          :ramdisk_cleanup => true,
          :ramdisk_dir     => '/ramdisk',
        }
      end

      it {
        should contain_file('/usr/local/bin/ramdisk_cleanup.sh').with({
          'ensure'  => 'file',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755',
          'content' => File.read(fixtures('ramdisk_cleanup.sh.default'))
        })
      }

      it {
        should contain_cron('ramdisk_cleanup.sh').with({
          'command' => '/usr/local/bin/ramdisk_cleanup.sh 21 d',
          'hour'    => '15',
          'minute'  => '30',
          'require' => 'File[/usr/local/bin/ramdisk_cleanup.sh]',
        })
      }
      context 'and and ramdisk_max_days is set to valid 242' do
        let(:params) do
          {
            :ramdisk_cleanup  => true,
            :ramdisk_dir      => '/ramdisk',
            :ramdisk_max_days => 242,
          }
        end
        it {
          should contain_cron('ramdisk_cleanup.sh').with({
            'command' => '/usr/local/bin/ramdisk_cleanup.sh 242 d',
            'hour'    => '15',
            'minute'  => '30',
            'require' => 'File[/usr/local/bin/ramdisk_cleanup.sh]',
          })
        }

      end
      context 'and and ramdisk_mail is set to valid false' do
        let(:params) do
          {
            :ramdisk_cleanup => true,
            :ramdisk_dir     => '/ramdisk',
            :ramdisk_mail    => false,
          }
        end
        it { should contain_file('/usr/local/bin/ramdisk_cleanup.sh').with_content(/^unset message$/) }
      end
    end
  end

  partially_supported_platforms = {
    'CentOS 7.0' =>
      {
        :operatingsystem        => 'CentOS',
        :operatingsystemrelease => '7.0.1406',
      },
    'OpenSuse 12.3' =>
      {
        :operatingsystem        => 'OpenSuSE',
        :operatingsystemrelease => '12.3',
      },
    'RedHat 6.7' =>
      {
        :operatingsystem        => 'RedHat',
        :operatingsystemrelease => '6.7',
      },
    'SLED 10.1' =>
      {
        :operatingsystem        => 'SLED',
        :operatingsystemrelease => '10.1',
      },
    'SLES 12.1' =>
      {
        :operatingsystem        => 'SLES',
        :operatingsystemrelease => '12.1',
      },
  }

  partially_supported_platforms.sort.each do |os,v|
    describe "on partially supported operatingsystem #{os}" do
      let(:facts) do
        {
          :operatingsystem        => v[:operatingsystem],
          :operatingsystemrelease => v[:operatingsystemrelease],
        }
      end

      context 'with default params only' do
        it { should compile.with_all_deps }
        it { should contain_class('fscleanup')}
        it { should have_file_resource_count(0) }
        it { should have_cron_resource_count(0) }
      end

      context 'with ramdisk_cleanup functionality activated' do
        let(:params) do
          {
            :ramdisk_cleanup => true,
            :ramdisk_dir     => '/ramdisk',
          }
        end
        it { should contain_file('/usr/local/bin/ramdisk_cleanup.sh') }
        it { should contain_cron('ramdisk_cleanup.sh') }
      end

      context 'with tmp_cleanup set to true' do
        let (:params) { { :tmp_cleanup => true } }
        it 'should fail' do
          expect { should contain_class(subject) }.to raise_error(Puppet::Error, %r(fscleanup::tmp_cleanup is only supported on SLED/SLES 11) )
        end
      end
    end
  end

  describe 'variable type and content validations' do
    # set needed custom facts and variables
    let(:facts) do
      {
        :operatingsystem        => 'SLES',
        :operatingsystemrelease => '11.4',
      }
    end
    let(:mandatory_params) do
      {
        #:param => 'value',
      }
    end

    validations = {
      'absolute_path' => {
        :name    => %w(tmp_short_dirs tmp_long_dirs),
        :valid   => ['/absolute/filepath','/absolute/directory/', %w(/array /with_paths)],
        :invalid => ['../invalid', 3, 2.42, %w(array), { 'ha' => 'sh' }, true, false, nil],
        :message => 'is not an absolute path',
      },
      'absolute_path_ramdisk_dir' => {
        :name    => %w(ramdisk_dir),
        :params  => { :ramdisk_cleanup => true },
        :valid   => ['/absolute/filepath','/absolute/directory/', %w(/array /with_paths)],
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
      'integer/string' => {
        :name    => %w(tmp_short_max_days tmp_long_max_days ramdisk_max_days),
        :valid   => [242, '242',-242, '-242', 2.42],
        :invalid => ['invalid', %w(array),{ 'ha' => 'sh' }, true, false, nil],
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
