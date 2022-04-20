lang en_US.UTF-8
keyboard us
timezone UTC
zerombr
clearpart --all --initlabel
autopart --type=plain --fstype=xfs --nohome
reboot
text
network --bootproto=dhcp
user --name=core --groups=wheel --password="{{kickstart_password}}"
services --enabled=ostree-remount
ostreesetup --nogpg --url={{ostreesetup_remote}} --osname=rhel --remote=edge --ref=rhel/8/x86_64/edge

%post
# Create ansible playbook to register device to Ansible automation platform
cat > /tmp/add_to_aap.yml <<EOF
---
- hosts: localhost
  gather_facts: true
  tasks:
    - name: create hostname from regex of mac address
      ansible.builtin.set_fact:
        edge_hostname: "{{ ansible_default_ipv4.macaddress | replace(':','') }}"

    - name: set hostname to mac ansible_all_ipv4_address
      ansible.builtin.hostname:
        name: "summit-demo-{{ edge_hostname }}"
        use: systemd

    - name: Update Ansible Tower inventory
      uri:
       url: https://controller-ansible-automation-platform.apps.carolina.dev02.red-chesterfield.com/api/v2/inventories/8/hosts/
       user: 'demo'
       password: 'summit2022'
       method: POST
       body: 
         name: "{{ ansible_hostname }}"
         variables: '{ipaddress: "{{ ansible_all_ipv4_addresses }}", macaddress: "{{ ansible_default_ipv4.macaddress }}" }'
       force_basic_auth: yes
       status_code: 201
       body_format: json
       validate_certs: no
EOF

ansible-playbook /tmp/add_to_aap.yml

%end
