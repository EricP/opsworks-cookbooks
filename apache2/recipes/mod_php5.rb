#
# Cookbook Name:: apache2
# Recipe:: php5 
#
# Copyright 2008, OpsCode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# debug/test : nullify this file by changing 'rhel' to 'notrhel'

bash 'install php56' do
  code <<-EOF
    INSTALLED="$(which php)"
    if [[ $INSTALLED != '' ]] ; then
      echo "PHP IS INSTALLED ..."
      php -v
      httpd -v
      else
      sudo yum update -y
      echo "REMOVING LEGACY APACHE & PHP SUPPORT FILES IF THEY EXIST"
      sudo yum -y erase httpd httpd-tools apr apr-util
      sudo yum -y remove php-*
      echo "INSTALLING PHP 5.6 (INCLUDES APACHE 2.4)"
      sudo yum -y install php56
      sudo yum -y install php56-opcache php56-mysqlnd php56-bcmath php56-devel php56-gd php56-mbstring php56-mcrypt php56-pdo php56-soap php56-xmlrpc php56-pecl-memcache
      # Fix apache user to allow httpd commands (outlined in .dev/commands/resolve.perms.sh)
      sudo useradd -g apache -d /var/www apache
      #
      #start for first deply on fresh server?
      sudo chkconfig httpd on
      sudo chkconfig --add httpd
      # CAN'T RESTART it stops the script in place!!!!!!!!!!!!
      # Maybe do another app that's called restart (to just do that)?
      #sudo service httpd start
      #sudo service httpd restart
      # chkconfig --list
      # action :nothing
    fi
  EOF
  #notifies :restart, resources(:service => 'apache2')
  timeout 120
end

# case node[:platform_family]
# when 'debian'
#   package 'libapache2-mod-php5' do
#     action :install
#     retries 3
#     retry_delay 5
#   end
# when 'rhel'
#   package 'php' do
#     action :install
#     retries 3
#     retry_delay 5
#     notifies :run, "execute[generate-module-list]", :immediately
#     not_if 'which php'
#   end

#   # remove stock config
#   file File.join(node[:apache][:dir], 'conf.d', 'php.conf') do
#     action :delete
#   end

#   # replace with debian config
#   template File.join(node[:apache][:dir], 'mods-available', 'php5.conf') do
#     source 'mods/php5.conf.erb'
#     notifies :restart, "service[apache2]"
#   end
# end

# apache_module 'php5' do
#   if platform_family?('rhel')
#     filename 'libphp5.so'
#   end
# end
