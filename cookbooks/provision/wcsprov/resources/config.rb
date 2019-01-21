actions [:provision]
default_action :provision

action :provision do

  wcs_dir = '/usr/local/etc/wcs/ami'
  chef_conf_dir = "#{wcs_dir}/chef_conf"

  [ wcs_dir, chef_conf_dir ].each do |path|
    directory path do
      owner 'root'
      group 'root'
      mode '0755'
      action :create
    end
  end

  bash 'change owner' do
    user 'root'
    code <<-EOH
    chown -R root:root #{wcs_dir}
    EOH
  end

  cookbook_file "/etc/motd" do
   source 'motd'
   owner 'root'
   group 'root'
   mode '0644'
   action :create
  end

  bash 'remove dinamyc motd' do
    code "rm -f /etc/update-motd.d/*"
    action :run
  end

  chef_gem 'aws-sdk-ec2' do
    action :install
  end

  git "#{wcs_dir}/community-stack" do
    repository 'https://github.com/wizzie-io/community-stack.git'
    revision '1.1.0'
    action :checkout
  end

  cookbook_file "#{wcs_dir}/wcs.conf" do
    source 'wcs.conf'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end

  bash 'install wcs' do
    code "env $(cat #{wcs_dir}/wcs.conf) #{wcs_dir}/community-stack/setups/linux_setup.sh"
    action :run
  end

  template '/etc/cloud/cloud.cfg.d/01-wdp.cfg' do
    source 'wdp-cloud-config.cfg.erb'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end

  cookbook_file "#{wcs_dir}/bootstrap.sh" do
    source 'bootstrap.sh'
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end

  cookbook_path = "#{wcs_dir}/bootstrap-cookbooks"
  template "#{chef_conf_dir}/solo.rb" do
    source 'solo.rb.erb'
    owner 'root'
    group 'root'
    mode '0755'
    variables(:cookbook_path => cookbook_path)
    action :create
  end

  template "#{chef_conf_dir}/node.json" do
    source 'node.json.erb'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end
end
