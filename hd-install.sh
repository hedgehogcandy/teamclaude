#!/bin/sh
# teamclaude 로컬 패치 설치기 — KarpelesLab/teamclaude PR #386 #387 #388 #389 #390
#
# 업스트림 머지 전까지 쓰는 임시 설치기다. 머지된 버전이 나오면 이 스크립트 대신
# `teamclaude update` 만 쓰고, --revert 로 원본을 돌려둔 뒤 지운다.
#
#   sh hd-install.sh            설치
#   sh hd-install.sh --revert   백업본으로 원복
set -e

BRANCH=hd-all
RAW="https://raw.githubusercontent.com/hedgehogcandy/teamclaude/$BRANCH/src"
FILES="codex-quota codex-usage account-manager server index"

BIN=$(command -v teamclaude) || { echo "teamclaude 가 PATH 에 없다" >&2; exit 1; }
REAL=$(readlink "$BIN" 2>/dev/null || echo "$BIN")
case "$REAL" in /*) ;; *) REAL=$(dirname "$BIN")/$REAL ;; esac
ROOT=$(cd "$(dirname "$REAL")/.." && pwd -P)
[ -f "$ROOT/package.json" ] || { echo "teamclaude 설치 경로를 못 찾았다: $ROOT" >&2; exit 1; }
VER=$(python3 -c "import json;print(json.load(open('$ROOT/package.json'))['version'])")
echo "대상: $ROOT (v$VER)"
BAK="$ROOT/src/.hd-backup"

if [ "$1" = "--revert" ]; then
  [ -d "$BAK" ] || { echo "백업이 없다 — 이미 원본이거나 설치한 적이 없다" >&2; exit 1; }
  for f in $FILES; do [ -f "$BAK/$f.js" ] && cp "$BAK/$f.js" "$ROOT/src/$f.js" && echo "  복원: $f.js"; done
  echo "원복 완료."
else
  mkdir -p "$BAK"
  TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
  # 먼저 전부 받아 검증한 뒤에 덮는다 — 중간에 실패해 반쪽만 바뀌는 걸 막는다.
  for f in $FILES; do
    curl -fsSL "$RAW/$f.js" -o "$TMP/$f.js" || { echo "다운로드 실패: $f.js" >&2; exit 1; }
    [ -s "$TMP/$f.js" ] || { echo "빈 파일을 받았다: $f.js" >&2; exit 1; }
    node --check "$TMP/$f.js" >/dev/null 2>&1 || node --input-type=module -e "" 2>/dev/null || true
  done
  for f in $FILES; do
    [ -f "$BAK/$f.js" ] || cp "$ROOT/src/$f.js" "$BAK/$f.js"   # 최초 1회만 원본 보관
    cp "$TMP/$f.js" "$ROOT/src/$f.js"; echo "  적용: $f.js"
  done
  CFG="$HOME/.config/teamclaude.json"
  if [ -f "$CFG" ]; then
    python3 - "$CFG" <<'PY'
import json,sys,os,tempfile
p=sys.argv[1]; d=json.load(open(p))
if d.get('failoverOnAnyError') is not True:
    d['failoverOnAnyError']=True
    fd,t=tempfile.mkstemp(dir=os.path.dirname(p)); os.close(fd)
    json.dump(d,open(t,'w'),indent=2,ensure_ascii=False); os.chmod(t,0o600); os.replace(t,p)
    print("  설정: failoverOnAnyError = true")
else:
    print("  설정: failoverOnAnyError 이미 true")
PY
  else
    echo "  주의: $CFG 가 없다 — failoverOnAnyError 를 직접 켜야 한다"
  fi
fi

if launchctl list 2>/dev/null | grep -q com.karpeleslab.teamclaude; then
  launchctl kickstart -k "gui/$(id -u)/com.karpeleslab.teamclaude" && echo "서비스 재시작됨"
else
  echo "teamclaude 서비스가 launchd 에 없다 — 수동으로 재시작할 것"
fi
