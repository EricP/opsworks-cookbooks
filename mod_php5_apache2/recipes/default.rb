include_recipe 'apache2'

# bash 'install php56' do
#   code <<-EOF
#     INSTALLED="$(which php)"
#     if [[ $INSTALLED != '' ]] ; then
#       echo "PHP IS INSTALLED ..."
#       php -v
#       httpd -v
#       else
#       sudo yum update -y
#       echo "REMOVING LEGACY APACHE & PHP SUPPORT FILES IF THEY EXIST"
#       sudo yum -y erase httpd httpd-tools apr apr-util
#       sudo yum -y remove php-*
#       echo "INSTALLING PHP 5.6 (INCLUDES APACHE 2.4)"
#       sudo yum -y install php56
#       sudo yum -y install php56-opcache php56-mysqlnd php56-bcmath php56-devel php56-gd php56-mbstring php56-mcrypt php56-pdo php56-soap php56-xmlrpc php56-pecl-memcache
#       # Fix apache user to allow httpd commands (outlined in .dev/commands/resolve.perms.sh)
#       sudo useradd -g apache -d /var/www apache
#       #
#       #start for first deply on fresh server?
#       sudo chkconfig httpd on
#       sudo chkconfig --add httpd
#       # CAN'T RESTART it stops the script in place!!!!!!!!!!!!
#       # Maybe do another app that's called restart (to just do that)?
#       #sudo service httpd start
#       #sudo service httpd restart
#       # chkconfig --list
#       # action :nothing
#     fi
#   EOF
#   #notifies :restart, resources(:service => 'apache2')
#   timeout 120
# end

node[:mod_php5_apache2][:packages].each do |pkg|
  package pkg do
    action :install
    ignore_failure(pkg.to_s.match(/^php-pear-/) ? true : false) # some pear packages come from EPEL which is not always available
    retries 3
    retry_delay 5
  end
end

node[:deploy].each do |application, deploy|
  if deploy[:application_type] != 'php'
    Chef::Log.debug("Skipping deploy::php application #{application} as it is not an PHP app")
    next
  end
  next if node[:deploy][application][:database].nil?

  bash "Enable network database access for httpd" do
    boolean = "httpd_can_network_connect_db"
    user "root"
    code <<-EOH
      semanage boolean --modify #{boolean} --on
    EOH
    not_if { OpsWorks::ShellOut.shellout("/usr/sbin/getsebool #{boolean}") =~ /#{boolean}\s+-->\s+on\)/ }
    only_if { platform_family?("rhel") && ::File.exist?("/usr/sbin/getenforce") && OpsWorks::ShellOut.shellout("/usr/sbin/getenforce").strip == "Enforcing" }
  end

  # case node[:deploy][application][:database][:type]
  # when "postgresql"
  #   include_recipe 'mod_php5_apache2::postgresql_adapter'
  # else # mysql or just backwards compatible
  #   include_recipe 'mod_php5_apache2::mysql_adapter'
  # end
end

include_recipe 'apache2::mod_php5'
