#!/bin/bash
# run on the VPS — applies iptables forwarding rules for all containers
set -e

REPO="$(cd "$(dirname "$0")/.." && pwd)"

python3 << EOF
import yaml, subprocess, os

repo = os.environ.get("REPO", "$REPO")
config_path = os.path.join(repo, "containers", "containers.yml")

with open(config_path) as f:
    containers = yaml.safe_load(f)

# flush existing container forwarding rules to avoid duplicates
result = subprocess.run(
    ['iptables', '-t', 'nat', '-L', 'PREROUTING', '--line-numbers', '-n'],
    capture_output=True, text=True
)

for c in containers:
    port = c.get('ssh_port')
    if not port:
        continue

    # check if rule already exists
    if f'dpt:{port}' in result.stdout:
        print(f"  [ok] port {port} already forwarded")
        continue

    print(f"  adding forwarding for port {port}")

    subprocess.run([
        'iptables', '-t', 'nat', '-A', 'PREROUTING',
        '-i', 'eth0', '-p', 'tcp', '--dport', str(port),
        '-j', 'DNAT', '--to-destination', f'10.10.0.2:{port}'
    ], check=True)

    subprocess.run([
        'iptables', '-A', 'FORWARD',
        '-i', 'eth0', '-o', 'wg0',
        '-p', 'tcp', '--dport', str(port),
        '-j', 'ACCEPT'
    ], check=True)

    print(f"  port {port} forwarded")

# persist rules
subprocess.run(['netfilter-persistent', 'save'], check=True)
print("rules saved")
EOF
