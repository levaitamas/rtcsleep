# rtcsleep

Put a Linux machine to sleep and have it wake up on its own at a given time,
using the hardware RTC alarm.

```console
$ rtcsleep 1h30m
Mode:   mem
Wake:   Fri 2026-10-16 14:28:22 CEST (in 1h 30m 00s)
...
Woke:   Fri 2026-10-16 14:28:41 CEST (slept ~5419s incl. suspend/resume)
```

The RTC alarm is set with `rtcwake -m no`, and the sleep itself goes through
systemd (`systemctl suspend`/`hibernate`/`poweroff`), so systemd sleep hooks
and inhibitor locks are honored, unlike a plain `rtcwake -m mem`.

## Usage

```
rtcsleep [-m mem|hibernate|off] [-n] <duration|time|date>
```

The wake target can be given as:

| Kind     | Examples                                    | Meaning                                  |
|----------|---------------------------------------------|------------------------------------------|
| Duration | `60`, `90s`, `15m`, `2h`, `1h30m`, `1d12h`  | from now; a bare number means seconds    |
| Time     | `07:00`, `7:30:15`, `7am`, `6:30pm`         | next occurrence, today or tomorrow       |
| Date     | `"2026-10-14 07:00"`, `"tomorrow 6:30"`     | anything `date -d` accepts               |

Duration units must come in `d`, `h`, `m`, `s` order, each at most once, and a
bare number is only accepted on its own: `1h30` is an error, not 1h 0m 30s.

Options:

- `-m MODE`: `mem` (suspend-to-RAM, default), `hibernate`, or `off` (power off).
- `-n`: dry run. Show the resolved wake time, set no alarm and do not sleep.
  Does not need root.
- `-h`: show help.

Examples:

```sh
rtcsleep -n 07:00            # when would "7:00" wake me up?
rtcsleep 45m                 # nap for 45 minutes
rtcsleep -m hibernate 06:30  # hibernate, wake up at the next 6:30
rtcsleep -m off "tomorrow 8:00"
```

### Behavior notes

- The wake time must be at least 30 seconds in the future; entering suspend
  can take a while (e.g. spinning down disks), and an alarm that fires before
  the machine is asleep is lost.
- A time-of-day target that is less than 30 seconds away rolls over to
  tomorrow.
- The script re-executes itself through `sudo` when not run as root. The wake
  time is resolved *before* that, so waiting at the password prompt does not
  shift it.
- In `mem` mode the script waits for the resume and prints when the machine
  woke up. If the suspend fails, or the machine has not actually suspended
  within 120 seconds (for example, because an inhibitor lock blocked it), the
  RTC alarm is cleared and the script exits with an error.
- If `systemctl` fails, the RTC alarm is cleared again.
- Once `systemctl` has accepted the request, the sleep can no longer be
  cancelled, so interrupting the script after that point (Ctrl-C, `kill`, or
  the shutdown itself in `hibernate` and `off` mode) leaves the RTC alarm set
  on purpose: a spurious wake-up is better than a machine that never wakes.

## Requirements

- Bash 4+
- GNU coreutils `date` (for parsing date expressions)
- `rtcwake` from util-linux, at `/usr/sbin/rtcwake` (Debian, Ubuntu) or
  `/usr/bin/rtcwake` (Fedora)
- systemd
- `sudo` (or run as root)
- An RTC that supports wake alarms (check `/sys/class/rtc/rtc0/wakealarm`).
  Whether it keeps UTC or local time is read from `/etc/adjtime`, as set by
  `hwclock`; without that file, UTC is assumed.

## Installation

```sh
sudo make install                 # installs to /usr/local/bin/rtcsleep
sudo make uninstall
make install PREFIX=~/.local      # per-user install
```

Or just copy `rtcsleep` anywhere on your `PATH`.

## Development

```sh
make check   # shellcheck + dry-run smoke tests (no root needed)
```

## License

[MIT](LICENSE)
