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

add_hashicorp_repo:
  cmd.run:
    - name: |
        {% if "Ubuntu" == grains["os"] %}
        wget -O /etc/apt/sources.list.d/hashicorp.list {{ kartaca.hashicorp_repo.debian.url }}/hashicorp.list
        {% elif "CentOS Stream" == grains["os"] %}
        wget -O /etc/yum.repos.d/hashicorp.repo {{ kartaca.hashicorp_repo.centos.url }}/hashicorp.repo
        {% endif %}
    - unless: |
        {% if "Ubuntu" == grains["os"] %}
        test -f /etc/apt/sources.list.d/hashicorp.list
        {% elif "CentOS Stream" == grains["os"] %}
        test -f /etc/yum.repos.d/hashicorp.repo
        {% endif %}
    - require_in:
      - pkg: gnupg

install_gpg_key:
  cmd.run:
    - name: |
        {% if "Ubuntu" == grains["os"] %}
        wget -O- {{ kartaca.hashicorp_repo.debian.gpg_key }} | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        {% elif "CentOS Stream" == grains["os"] %}
        rpmkeys --import {{ kartaca.hashicorp_repo.centos.gpg_key }}
        {% endif %}
    - unless: |
        {% if "Ubuntu" == grains["os"] %}
        test -f /usr/share/keyrings/hashicorp-archive-keyring.gpg
        {% elif "CentOS Stream" == grains["os"] %}
        test -f /etc/pki/rpm-gpg/RPM-GPG-KEY-hashicorp
        {% endif %}
    - require_in:
      - pkg: gnupg

install_terraform:
  pkg.installed:
    - name: terraform
    - version: {{ kartaca.hashicorp_repo.debian.terraform_version }}
    - require:
      - cmd: add_hashicorp_repo
      - cmd: install_gpg_key

configure_timezone:
  timezone.system_set:
    - name: {{ kartaca.timezone }}

enable_ip_forwarding:
  sysctl.present:
    - name: net.ipv4.ip_forward
    - value: 1
    - config_file: /etc/sysctl.conf

install_required_packages:
  pkg.installed:
    - pkgs: {{ kartaca.required_packages }}

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
