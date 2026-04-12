#!/bin/bash
set -e

REPO="$(cd "$(dirname "$0")/.." && pwd)"

python3 << EOF
import yaml, subprocess, os

repo = os.environ.get("REPO", "$REPO")


config_path = os.path.join(repo, "containers", "containers.yml")

with open(config_path) as f:
    containers = yaml.safe_load(f)

result = subprocess.run(
    ['incus', 'list', '--format', 'csv', '-c', 'n'],
    capture_output=True, text=True
)

existing = set(filter(None, result.stdout.strip().split('\n')))

for c in containers:
    name = c['name']

    if name in existing:
        print(f"  [ok] {name} exists")
        continue

    print(f"creating {name}")

    subprocess.run([
        'incus', 'launch', 'images:ubuntu/24.04', name,
        '--network', c.get('bridge', 'incusbr1'),
        '-q'
    ], check=True)

    subprocess.run([
        'incus', 'config', 'set', name,
        'limits.cpu', str(c.get('cpu', 2))
    ], check=True)

    subprocess.run([
        'incus', 'config', 'set', name,
        'limits.memory', c.get('memory', '2GB')
    ], check=True)


    print(f"{name} ready")

for c in containers:
    name = c['name']

    if 'user' not in c or 'ssh_key' not in c:
        continue

    user = c['user']
    key  = c['ssh_key'].strip()

    print(f"  configuring ssh for {name} ({user})")

    subprocess.run([
        'incus', 'exec', name, '--',
        'bash', '-c', 'apt-get install -y -q openssh-server && systemctl enable --now ssh'
    ], check=True)

    ssh_port = c.get('ssh_port', 2223)

    devices = subprocess.run(
        ['incus', 'config', 'device', 'show', name],
        capture_output=True, text=True
    ).stdout

    if 'ssh-proxy' not in devices:
        subprocess.run([
            'incus', 'config', 'device', 'add', name, 'ssh-proxy', 'proxy',
            f'listen=tcp:0.0.0.0:{ssh_port}',
            'connect=tcp:127.0.0.1:22'
        ], check=True)
        print(f"  proxy added on port {ssh_port}")

    setup_cmd = f'''
set -e
id -u {user} >/dev/null 2>&1 || useradd -m -s /bin/bash {user}
usermod -aG sudo {user}
mkdir -p /home/{user}/.ssh
printf '%s\\n' '{key}' > /home/{user}/.ssh/authorized_keys
chmod 700 /home/{user}/.ssh
chmod 600 /home/{user}/.ssh/authorized_keys
chown -R {user}:{user} /home/{user}/.ssh
'''

    subprocess.run([
        'incus', 'exec', name, '--', 'bash', '-c', setup_cmd
    ], check=True)

    print(f"  ssh ready for {user}@{name}")
EOF
