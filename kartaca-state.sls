{% set kartaca = salt['pillar.get']('kartaca', {}) %}

create_kartaca_group:
  group.present:
    - name: {{ kartaca.group.name }}
    - gid: {{ kartaca.group.gid }}

create_kartaca_user:
  user.present:
    - name: {{ kartaca.user.name }}
    - uid: {{ kartaca.user.uid }}
    - gid: {{ kartaca.user.gid }}
    - home: {{ kartaca.user.home }}
    - shell: {{ kartaca.user.shell }}
    - password: {{ kartaca.user.password }}
    - require:
      - group: create_kartaca_group

grant_sudo_privileges:
  cmd.run:
    - name: |
        {% if "Ubuntu" == grains["os"] %}
        echo "{{ kartaca.user.name }} ALL=(ALL) NOPASSWD: /usr/bin/apt" >> /etc/sudoers
        {% elif "CentOS Stream" == grains["os"] %}
        echo "{{ kartaca.user.name }} ALL=(ALL) NOPASSWD: /usr/bin/yum" >> /etc/sudoers
        {% endif %}
    - unless: |
        {% if "Ubuntu" == grains["os"] %}
        grep -q "{{ kartaca.user.name }} ALL=(ALL) NOPASSWD: /usr/bin/apt" /etc/sudoers
        {% elif "CentOS Stream" == grains["os"] %}
        grep -q "{{ kartaca.user.name }} ALL=(ALL) NOPASSWD: /usr/bin/yum" /etc/sudoers
        {% endif %}
    - require:
      - user: create_kartaca_user

install_gpg_key:
  cmd.run:
    - name: |
        {% if "Ubuntu" == grains["os"] %}
        sudo apt update -y %% sudo apt install -y gpg
        wget -0- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        apt update -y
        {% elif "CentOS Stream" == grains["os"] %}
        yum -y install gpg
        wget -0- https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo | sudo tee /etc/yum.repos.d/hashicorp.repo
        yum list available | grep hashicorp
        {% endif %}
    - unless: |
        {% if "Ubuntu" == grains["os"] %}
        test -f /usr/share/keyrings/hashicorp-archive-keyring.gpg
        {% elif "CentOS Stream" == grains["os"] %}
        test -f /etc/yum.repos.d/hashicorp.repo
        {% endif %}


install_terraform:
  pkg.installed:
    - names:
        - terraform
    - version: 1.6.4
    - require:
        - cmd: install_gpg_key



configure_timezone:
  timezone.system_set:
    - name: {{ kartaca.timezone }}

enable_ip_forwarding:
  sysctl.present:
    - name: net.ipv4.ip_forward
    - value: 1
    - config: /etc/sysctl.conf

install_required_packages:
  pkg.installed:
    - names: {{ kartaca.required_packages }}

configure_hosts_entries:
  file.blockreplace:
    - name: /etc/hosts
    - marker_start: "# BEGIN SALT MANAGED CONTENT"
    - marker_end: "# END SALT MANAGED CONTENT"
    - content: |
        # BEGIN SALT MANAGED CONTENT
        {% for entry in kartaca.hosts_entries %}
        {{ entry.ip }}    {{ entry.host }}
        {% endfor %}
        # END SALT MANAGED CONTENT
    - backup: '.bak'
