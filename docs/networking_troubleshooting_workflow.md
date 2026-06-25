# Networking Troubleshooting Workflow

Use this workflow for interface detection, link state, IP configuration, DNS, throughput, and NIC driver or firmware clue gathering.

## Why Networking Matters For AI/HPC

Distributed AI and HPC systems depend on reliable node-to-node and storage connectivity. Network issues can look like application failures, slow training, job timeouts, package download failures, storage stalls, or cluster communication problems.

This workflow covers general Linux networking and evidence collection. InfiniBand, RDMA, NCCL, and distributed GPU fabric diagnostics are listed as future improvements unless those tools are actually installed and available.

## Baseline Commands

```bash
ip addr
ip link
ip -s link
ip route
ethtool <interface>
ethtool -i <interface>
ethtool -S <interface>
ping <target>
traceroute <target>
ss -tulpn
getent hosts <hostname>
resolvectl status
lspci | grep -i ethernet
dmesg | grep -i eth
```

## Interface Not Detected

Symptoms:

- Expected NIC missing from `ip link`.
- Expected NIC missing from PCIe inventory.
- Interface naming changed after update.

Evidence:

```bash
ip link
lspci -nnk | grep -A3 -Ei "ethernet|network|mellanox|broadcom|intel"
lspci | grep -Ei "ethernet|network|mellanox|broadcom|intel"
dmesg | grep -Ei "eth|enp|eno|mlx|network|firmware|error|fail"
```

Next action:

- Compare against expected inventory.
- Check recent OS, kernel, firmware, or hardware changes.
- Escalate before driver, firmware, or physical changes.

## Link Down

Symptoms:

- Interface exists but state is `DOWN`.
- No carrier detected.
- Expected link speed is not negotiated.

Commands:

```bash
ip link
ip -s link
ethtool <interface>
journalctl -k | grep -Ei "link is down|link is up|eth|enp|eno"
```

Next action:

- Confirm expected cable, switch port, and VLAN context with network owner.
- Do not change switch or NIC settings without approval.

## IP Configuration Issue

Symptoms:

- Interface has no IP.
- IP is in wrong subnet.
- Default route missing.
- Duplicate IP suspected.

Commands:

```bash
ip addr
ip route
```

Next action:

- Confirm DHCP/static configuration expectation.
- Capture route table and interface state.
- Escalate before changing persistent network config.

## DNS Issue

Symptoms:

- IP ping works but hostname lookup fails.
- Package managers or applications fail by hostname.

Commands:

```bash
cat /etc/resolv.conf
getent hosts google.com
resolvectl status
ping -c 4 8.8.8.8
ping -c 4 google.com
```

External connectivity tests should be clearly labeled and may not be appropriate on isolated lab networks.

## Throughput Issue

Symptoms:

- Link works but transfers are slow.
- Expected link speed is not negotiated.
- Application times out under load.

Evidence:

```bash
ethtool <interface>
ip -s link
ss -tulpn
dmesg | grep -Ei "eth|enp|eno|link|reset|timeout|error|drop"
```

Interpretation:

- Check negotiated speed and duplex.
- Look for interface errors, drops, resets, or firmware messages.
- Confirm whether the observed throughput matches network design.
- Run throughput tests such as `iperf3` only when both endpoints and traffic impact are approved.

## NIC Driver And Firmware Clues

```bash
ethtool -i <interface>
lspci -vv | grep -A20 -Ei "ethernet|network"
dmesg | grep -Ei "firmware|eth|enp|eno|mlx"
```

Record driver and firmware versions where available. Escalate if the next step is firmware change, driver change, or switch-side modification.

## Future Improvements

- InfiniBand diagnostics with `ibstat`, `ibv_devinfo`, and subnet manager checks.
- RDMA validation workflow.
- NCCL communication test examples.
- Distributed GPU networking issue templates.
- Fabric topology documentation examples.

## Customer-Facing Urgency

In AI/HPC environments, a networking issue can block model training, storage mounts, cluster scheduling, remote support, or customer acceptance testing. Record urgency in terms of affected node count, affected workload, whether there is a workaround, and whether the issue blocks validation or delivery.

## Evidence To Attach

- `ip addr`
- `ip link`
- `ip route`
- `ethtool <interface>`
- `ethtool -i <interface>`
- `ss -tulpn`
- NIC-related `lspci`
- Network-related kernel logs
- DNS and ping test results, if authorized
