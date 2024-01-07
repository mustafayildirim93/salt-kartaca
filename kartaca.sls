{% set ip_block = "192.168.168.128/28" %}
{% set ip_list = salt['network.ip_addrs'](ip_block) %}

kartaca:
  user:
    name: kartaca
    uid: 2023
    gid: 2023
    home: /home/krt
    shell: /bin/bash
    password: kartaca2023

  group:
    name: kartaca
    gid: 2023

  timezone: Istanbul

  required_packages:
    - htop
    - tcptraceroute
    - iputils-ping
    - bind-utils
    - sysstat
    - mtr
    - gnupg  # Ekstra paket: GPG'yi yükleyin

  hashicorp_repo:
    debian:
      url: https://apt.releases.hashicorp.com
      gpg_key: https://apt.releases.hashicorp.com/gpg
      terraform_version: 1.0.0
    centos:
      url: https://rpm.releases.hashicorp.com/RHEL
      gpg_key: https://rpm.releases.hashicorp.com/repodata/repomd.xml.key
      terraform_version: 1.0.0

  hosts_entries:
    {% for ip in ip_list %}
    - ip: {{ ip }}
      host: kartaca.local
    {% endfor %}
