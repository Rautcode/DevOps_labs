# 18 · Linux administration (Extra, ~3h)

> **Guided version:** run `bash lab.sh 18` from the repo root. It explains each step, has you type the commands yourself, and checks your hands-on tasks. This page is the reference. **Unlocks after module 01.**

**Goal:** the daily skills of a sysadmin on a throwaway Linux server: users and permissions, processes and signals, disk and memory, logs, cron, systemd units, SSH keys and sudo.

| File | What it is |
|---|---|
| [Dockerfile](Dockerfile) | the practice server (Debian 12 with procps, cron, systemd tools, sudo, iproute2) |

The shortcut `lx CMD` runs `CMD` inside the practice server (`docker exec lab-linux CMD`). For pipes and redirects inside the server write `lx bash -c '...'`.

## Cheat sheet
| Task | Command |
|---|---|
| Who am I, who is alice | `id`, `id alice` |
| Create user / group, add to group | `useradd -m alice`, `groupadd team`, `usermod -aG team alice` |
| Owner, group, mode | `chown alice:team f`, `chmod 750 f`, `stat -c '%A %U:%G' f` |
| Find processes / stop them | `ps aux`, `pgrep -f name`, `pkill -TERM -f name` (SIGKILL last) |
| Disk / memory | `df -h`, `du -sh /var/*`, `free -m`, `find / -xdev -size +40M` |
| Logs | `tail -f file`, `grep -c ERROR file` |
| Schedule | `/etc/cron.d/job`: `* * * * * root command` |
| Service | unit file with `ExecStart`, `User`, `Restart=on-failure`; `systemd-analyze verify unit` |
| SSH key permissions | `.ssh` 700, private key 600; `visudo -cf file` before saving sudoers |

## Break it
1. `chmod 000` a directory and read the error; fix it.
2. Fill `/tmp` with `fallocate -l 500M` and watch `df`; find the culprit with `find`.
3. Put a typo in a unit file and read what `systemd-analyze verify` says.

## Industry notes
Interviews ask about permissions, processes, disk full, DNS and "a server is slow: what do you check?" Memorise the USE method (utilisation, saturation, errors). In production prefer journald (`journalctl -u service`), `logrotate`, configuration management (module 13) over hand edits, and key-only SSH with no root login.
