# -*- mode: ruby -*-
# vi: set ft=ruby :

$script = <<~SCRIPT
  # Add zsh
  sudo apt-get update
  echo "Installing zsh..."
  sudo apt-get install zsh -y
  sudo chsh -s /bin/zsh vagrant
  
  # Oh My Zsh
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  
  # OMZ Theme
  sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/g' ~/.zshrc
  
  echo "Installing Docker..."
  sudo apt-get update
  sudo apt-get remove docker docker-engine docker.io
  echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections
  sudo apt-get install apt-transport-https ca-certificates curl software-properties-common -y
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  sudo apt-key add -
  sudo apt-key fingerprint 0EBFCD88
  sudo add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) \
        stable"
  sudo apt-get update
  sudo apt-get install -y docker-ce
  # Restart docker to make sure we get the latest version of the daemon if there is an upgrade
  sudo service docker restart
  # Make sure we can actually use docker as the vagrant user
  sudo usermod -aG docker vagrant
  sudo docker --version
  
  # Packages required for nomad & consul
  sudo apt-get install unzip curl vim -y
  
  echo "Installing Nomad..."
  NOMAD_VERSION=0.12.5
  cd /tmp/
  curl -sSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o nomad.zip
  unzip nomad.zip
  sudo install nomad /usr/bin/nomad
  sudo mkdir -p /etc/nomad.d
  sudo chmod a+w /etc/nomad.d
  
  sudo mkdir -p /etc/systemd/resolved.conf.d
  
  echo "Installing Consul..."
  CONSUL_VERSION=1.8.4
  curl -sSL https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip > consul.zip
  unzip /tmp/consul.zip
  sudo install consul /usr/bin/consul
  (
  cat <<-EOF
  [Unit]
  Description=consul agent
  Requires=network-online.target
  After=network-online.target
  
  [Service]
  Restart=on-failure
  ExecStart=/usr/bin/consul agent -dev -client=0.0.0.0
  ExecReload=/bin/kill -HUP $MAINPID
  
  [Install]
  WantedBy=multi-user.target
  EOF
  ) | sudo tee /etc/systemd/system/consul.service
  consul -autocomplete-install
  sudo systemctl enable consul.service
  sudo systemctl start consul
  
  # # Systemd-resolved configuration
  (
  cat <<-EOF
  [Resolve]
  DNS=127.0.0.1
  Domains=~consul
  EOF
  ) | sudo tee /etc/systemd/resolved.conf.d/consul.conf
  
  sudo iptables -t nat -A OUTPUT -d localhost -p udp -m udp --dport 53 -j REDIRECT --to-ports 8600
  sudo iptables -t nat -A OUTPUT -d localhost -p tcp -m tcp --dport 53 -j REDIRECT --to-ports 8600
  
  sudo systemctl daemon-reload
  sudo systemctl restart systemd-networkd
  sudo systemctl restart systemd-resolved
  
  for bin in cfssl cfssl-certinfo cfssljson
  do
    echo "Installing $bin..."
    curl -sSL https://pkg.cfssl.org/R1.2/${bin}_linux-amd64 > /tmp/${bin}
    sudo install /tmp/${bin} /usr/local/bin/${bin}
  done
  nomad -autocomplete-install
  
  # TMux Configuration
  echo "Configuring tmux..."
  (
  cat <<-EOF
  set-option -g mouse on
  set-option -g set-titles on
  set-option -g set-titles-string '#T'
  
  # Toggle mouse on
  bind-key M \\\\
    set-option -g mouse on \\\\;\\\\
    display-message 'Mouse: ON'
  
  # Toggle mouse off
  bind-key m \\\\
    set-option -g mouse off \\\\;\\\\
    display-message 'Mouse: OFF'
  EOF
  ) | tee ~/.tmux.conf
  
  # Pre-configure clients
  sudo mkdir -p /opt/client1/cockroachdb/data
  
  # Nomad agents configuration
  
  (
  cat <<-EOF
  [Unit]
  Description=nomad agent for client1
  
  [Service]
  Restart=on-failure
  ExecStart=/usr/bin/nomad agent -config /vagrant/lab3/client1.hcl
  ExecReload=/bin/kill -HUP $MAINPID
  
  [Install]
  WantedBy=multi-user.target
  EOF
  ) | sudo tee /etc/systemd/system/nomad-client1.service
  sudo systemctl enable nomad-client1.service
  sudo systemctl start nomad-client1
  
  (
  cat <<-EOF
  [Unit]
  Description=nomad agent for client2
  
  [Service]
  Restart=on-failure
  ExecStart=/usr/bin/nomad agent -config /vagrant/lab3/client2.hcl
  ExecReload=/bin/kill -HUP $MAINPID
  
  [Install]
  WantedBy=multi-user.target
  EOF
  ) | sudo tee /etc/systemd/system/nomad-client2.service
  sudo systemctl enable nomad-client2.service
  sudo systemctl start nomad-client2
  
  (
  cat <<-EOF
  [Unit]
  Description=nomad agent for server
  
  [Service]
  Restart=on-failure
  ExecStart=/usr/bin/nomad agent -config /vagrant/lab3/server.hcl
  ExecReload=/bin/kill -HUP $MAINPID
  
  [Install]
  WantedBy=multi-user.target
  EOF
  ) | sudo tee /etc/systemd/system/nomad-server.service
  sudo systemctl enable nomad-server.service
  sudo systemctl start nomad-server
  
  echo "Installing cni plugins..."
  curl -sSL -o cni-plugins.tgz https://github.com/containernetworking/plugins/releases/download/v0.8.6/cni-plugins-linux-amd64-v0.8.6.tgz
  sudo mkdir -p /opt/cni/bin
  sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz
  rm cni-plugins.tgz
  
SCRIPT

Vagrant.configure(2) do |config|
  config.vm.box = 'bento/ubuntu-20.04' # 20.04 LTS
  config.vm.hostname = 'nomad'
  config.vm.provision 'shell', inline: $script, privileged: false

  # Expose the nomad api and ui to the host
  config.vm.network 'forwarded_port', guest: 4646, host: 4646, auto_correct: true, host_ip: '127.0.0.1'

  # Cockroachdb
  config.vm.network 'forwarded_port', guest: 26_257, host: 26_257, auto_correct: true, host_ip: '127.0.0.1'
  config.vm.network 'forwarded_port', guest: 8080, host: 8080, auto_correct: true, host_ip: '127.0.0.1'

  config.vm.network 'forwarded_port', guest: 6379, host: 6379, auto_correct: true, host_ip: '127.0.0.1'
  config.vm.network 'forwarded_port', guest: 3306, host: 3306, auto_correct: true, host_ip: '127.0.0.1'

  # Consul api and ui
  config.vm.network 'forwarded_port', guest: 8500, host: 8500, auto_correct: true, host_ip: '127.0.0.1'
  config.vm.network 'forwarded_port', guest: 8600, host: 8600, auto_correct: true, host_ip: '127.0.0.1'

  # Increase memory for Parallels Desktop
  config.vm.provider 'parallels' do |p, _o|
    p.memory = 4096
    p.cpus = 4
  end

  # Increase memory for Virtualbox
  config.vm.provider 'virtualbox' do |vb|
    vb.memory = 4096
    vb.cpus = 4
  end

  # Increase memory for VMware
  %w[vmware_fusion vmware_workstation].each do |p|
    config.vm.provider p do |v|
      v.vmx['memsize'] = 4096
      v.vmx['numvcpus'] = 4
    end
  end
end
