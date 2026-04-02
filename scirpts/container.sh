#!/bin/bash
set -e
REPO="$(cd "$(dirname "$0")/.." && pwd)"

python3 << EOF
import yaml, subprocess

with open('$REPO/containers.yml') as f:
    containers = yaml.safe_load(f)['containers']

result = subprocess.run(['incus', 'list', '--format', 'csv', '-c', 'n'],
    capture_output=True, text=True)
existing = set(result.stdout.strip().split('\n'))

for c in containers:
    name = c['name']
    if name in existing:
        print(f"  [ok] {name} exists")
        continue

    print(f"  [+] creating {name}")
    subprocess.run([
        'incus', 'launch', 'images:ubuntu/24.04', name,
        '--network', c.get('bridge', 'incusbr1'),
        '-q'
    ], check=True)

    subprocess.run(['incus', 'config', 'set', name,
        'limits.cpu', str(c.get('cpu', 2))], check=True)
    subprocess.run(['incus', 'config', 'set', name,
        'limits.memory', c.get('memory', '2GB')], check=True)

    if 'user' in c and 'ssh_key' in c:
        user = c['user']
        key  = c['ssh_key']
        subprocess.run(['incus', 'exec', name, '--', 'bash', '-c',
            f'useradd -m -s /bin/bash {user} && '
            f'mkdir -p /home/{user}/.ssh && '
            f'echo "{key}" > /home/{user}/.ssh/authorized_keys && '
            f'chmod 700 /home/{user}/.ssh && '
            f'chmod 600 /home/{user}/.ssh/authorized_keys && '
            f'chown -R {user}:{user} /home/{user}/.ssh'
        ], check=True)

    print(f"  [+] {name} ready")
EOF
