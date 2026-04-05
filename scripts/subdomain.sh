#!/bin/bash
set -e
REPO="$(cd "$(dirname "$0")/.." && pwd)"

python3 << EOF
import yaml, subprocess

with open('$REPO/subdomains.yml') as f:
    subdomains = yaml.safe_load(f)['subdomains']

for s in subdomains:
    sub       = s['subdomain']
    container = s['target']
    port      = s['port']

    result = subprocess.run(
        ['incus', 'list', container, '--format', 'csv', '-c', '4'],
        capture_output=True, text=True)
    ip = result.stdout.strip().split(' ')[0]

    if not ip:
        print(f"  [!] {container} has no IP, skipping {sub}")
        continue

    conf = f"""server {{
    listen 80;
    server_name {sub}.tinkerhub.org;

    location / {{
        proxy_pass http://{ip}:{port};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }}
}}
"""
    tmp = f"/tmp/{sub}.tinkerhub.org.conf"
    with open(tmp, 'w') as f:
        f.write(conf)

    subprocess.run([
        'incus', 'file', 'push', tmp,
        f'reverse-proxy/etc/nginx/sites-enabled/{sub}.tinkerhub.org.conf'
    ], check=True)
    print(f"  [+] {sub}.tinkerhub.org -> {ip}:{port}")
EOF

incus exec reverse-proxy -- nginx -t && incus exec reverse-proxy -- nginx -s reload
