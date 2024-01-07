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

  timezone: Europe/Istanbul

  required_packages:
    - htop
    - tcptraceroute
    - iputils-ping
    - bind-utils
    - sysstat
    - mtr
    - gnupg

  hosts_entries:
    {% for ip in ip_list %}
    - ip: {{ ip }}
      host: kartaca.local
    {% endfor %}
