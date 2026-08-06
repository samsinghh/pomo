# pomo

A minimal pomodoro timer for macOS, with a popup timer! 

<img width="1512" height="578" alt="Screen Recording 2026-08-06 at 1 02 23 PM" src="https://github.com/user-attachments/assets/0cd15a7c-5c96-4f73-b219-0e36a7d4a52f" />

## Install

```sh
brew install samsinghh/tap/pomo
```
Or from source:
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
| `--sessions/-s <n>` | 4 | work sessions per cycle |
| `--long-break/-l <minutes>` | 15 | break after the last session |

**Example:**
```sh
pomo 25 5
```
