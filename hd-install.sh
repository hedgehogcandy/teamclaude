#!/bin/sh
# 폐기됨 — 실행하지 마세요. (2026-09-14)
#
# 이 스크립트는 teamclaude 소스 5파일을 통째로 덮어썼습니다. 2026-09-14 19:46 에
# 맥미니에서 그렇게 해서 다른 세션의 패치를 지웠고, 두 패치가 같은 스트림을 각자
# getReader() 로 잠가 `ReadableStream is locked` 15건 · 5xx 13건, 코덱스 요청이
# 약 3분 전멸했습니다.
#
# 같은 파일을 두 주체가 "전체 덮어쓰기"로 관리하면 반드시 서로를 지웁니다.
#
# 지금 맞는 방법:
#   - 로컬 패치 적용은 각 맥의 launchd 진입점이 멱등으로 처리합니다
#       ~/.config/hd/teamclaude-patches/ensure-and-start.sh
#   - 재시작은 이것만:
#       launchctl kickstart -k gui/$(id -u)/com.karpeleslab.teamclaude
#   - 업스트림에 머지되면(PR #386~#391) 로컬 패치는 전부 불필요합니다.
#
# 소유 세션: hypeduck-08
echo "이 설치기는 폐기됐습니다 — teamclaude 소스를 덮어써 장애를 냅니다." >&2
echo "자세한 내용은 이 파일의 주석과 PR #386~#391 을 보세요." >&2
exit 1
