# ClaudeNotifier

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) hooks용 macOS 네이티브 알림 도구.

Swift `UNUserNotificationCenter` 기반으로 제작 — macOS Sonoma 이상에서 호환성 문제가 있는 `terminal-notifier`를 대체합니다.

## 주요 기능

- **Alert 스타일 알림** — 사용자가 행동할 때까지 유지
- **클릭 시 VS Code 프로젝트 창 포커싱** — `NSWorkspace.open` API 사용
- **프로그래밍적 알림 제거** — `remove` 명령
- **그룹 기반 알림 관리** — 같은 그룹 ID는 이전 알림을 교체
- **IDE 포커스 감지** — VS Code/Cursor 활성 시 알림 스킵
- **VS Code 아이콘** 표시
- **Dock 아이콘 없음** — 백그라운드 앱 (`LSUIElement`)

## 요구사항

- macOS 14.0 (Sonoma) 이상
- Xcode Command Line Tools (`xcode-select --install`)

## 빌드 및 설치

```bash
./build.sh
```

실행 결과:
1. Swift 소스 컴파일
2. VS Code 아이콘 포함 앱 번들 생성
3. `~/.claude/notifier/ClaudeNotifier.app`에 설치
4. `~/bin/claude-notifier` 심링크 생성

## 초기 설정

알림 권한 요청 (최초 1회):

```bash
open ~/.claude/notifier/ClaudeNotifier.app --args setup
```

이후 **시스템 설정 > 알림 > ClaudeNotifier**에서 알림 스타일을 **"알림(경고)"**으로 변경 (배너 아님).

## 사용법

`open` 명령의 포커스 탈취 부수효과를 방지하기 위해 바이너리를 직접 백그라운드(`&`)로 실행:

```bash
NOTIFIER_BIN="$HOME/.claude/notifier/ClaudeNotifier.app/Contents/MacOS/ClaudeNotifier"
```

### 알림 전송

```bash
"$NOTIFIER_BIN" send \
  --title "제목" \
  --message "본문 텍스트" \
  --subtitle "부제목" \
  --sound "default" \
  --group "my-group" \
  --project-dir "/프로젝트/경로" &
```

### 알림 제거

```bash
"$NOTIFIER_BIN" remove --group "my-group" &
"$NOTIFIER_BIN" remove --all &
```

## Claude Code Hooks 연동

`~/.claude/hooks/`에 위치한 3개의 hook 스크립트와 함께 사용:

| Hook | 스크립트 | 용도 |
|------|----------|------|
| PermissionRequest | `notify-permission.sh` | 도구 승인 필요 시 알림 |
| Stop | `notify-complete.sh` | 작업 완료 시 알림 |
| PostToolUse | `notify-dismiss.sh` | 승인 후 권한 알림 제거 |

### 알림 제거 트리거

| 알림 타입 | 트리거 | 메커니즘 |
|-----------|--------|----------|
| 권한 알림 | 도구 실행 완료 | `notify-dismiss.sh` (PostToolUse hook) |
| 권한 알림 | transcript 변경 | 백그라운드 워처 (2초 간격 감시) |
| 완료 알림 | 새 프롬프트 입력 | 백그라운드 워처 (5초 대기 후 감시) |

## 라이선스

MIT
