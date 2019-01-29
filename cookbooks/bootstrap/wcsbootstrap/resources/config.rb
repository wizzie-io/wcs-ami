include WcsBoostrap::Helper

actions :config
default_action :config

action :config do

  wcs_dir = '/usr/local/etc/wcs/ami'
  wizzie_home = '/home/wizzie'

  bash 'create wizzie user' do
   code <<-EOH
   adduser wizzie --home #{wizzie_home} --shell /bin/bash --gecos "" --disabled-password
   echo "wizzie ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/95-wizzie-users
   cp -r /home/ubuntu/.ssh #{wizzie_home} && chown -R wizzie #{wizzie_home}/.ssh
   sed -i 's/\\(.*\\)ubuntu\\(.*\\)/\\1wizzie\\2/g' /root/.ssh/authorized_keys
   EOH
  end

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
