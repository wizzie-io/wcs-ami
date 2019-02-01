include WcsBoostrap::Helper

actions :config
default_action :config

action :config do

  wcs_dir = '/usr/local/etc/wcs/ami'

  template "#{wcs_dir}/wcs.conf" do
    source 'wcs.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables(:public_ip => public_ip,
              :secret_key => random_key(32),
              :db_password => random_key(32))
    action :create
  end

  bash 'configure wcs' do
    code "env $(cat #{wcs_dir}/wcs.conf) #{wcs_dir}/community-stack/setups/linux_setup.sh"
  end

end
