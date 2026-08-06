# pomo

A minimal pomodoro timer for macOS, with a popup timer!

<img width="1512" height="591" alt="Screenshot 2026-08-06 at 11 12 43 AM" src="https://github.com/user-attachments/assets/1bd0535e-eaaa-48a7-9cd0-f361377cbb6d" />

## Install

```sh
git clone https://github.com/samsinghh/pomo.git
cd pomo
make install
```

## Usage

```sh
pomo [work-minutes] [break-minutes]   # defaults: 25 5
```

| Option | Default | |
|---|---|---|
| `--sessions <n>` | 4 | work sessions per cycle |
| `--long-break <minutes>` | 15 | break after the last session |

**Example:**
```sh
pomo 25 5
```

## Development

```sh
make        # release build into .build/release/pomo
make test   # run the unit tests
```
