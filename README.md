# pomo

A minimal pomodoro timer for macOS, with a popup timer! 

<img width="1512" height="578" alt="pomo_demo" src="https://github.com/user-attachments/assets/dd1c0182-c134-4eb2-bf23-6e5e5c1f0adf" />

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
