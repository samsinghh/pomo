# pomo

A minimal pomodoro timer for macOS, with a popup timer!

<img width="1512" height="620" alt="image" src="https://github.com/user-attachments/assets/a6457b6e-348b-4a4f-8675-8839cfb906d6" />

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
| `--sessions <n>` | 4 | work sessions per cycle |
| `--long-break <minutes>` | 15 | break after the last session |

**Example:**
```sh
pomo 25 5
```
