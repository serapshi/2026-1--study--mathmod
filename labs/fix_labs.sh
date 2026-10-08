#!/usr/bin/env bash
# Исправляет отчёты labNN (по умолчанию lab01..lab08):
#  - шрифт моноширинного текста DejaVu Sans Mono (JuliaMono без кириллицы)
#  - engine: julia и julia: exeflags раскомментируются в _quarto.yml
#  - pdf-engine: xelatex раскомментируется
#  - monofont добавляется под format: pdf:, если его нет
#  - в Makefile убирается '-@' (ошибки видны) и задаётся GKSwstype=100
#  - проверяются include-пути в отчёте и выводятся отсутствующие файлы
#
# Использование:
#   bash fix_labs.sh                                  # dry-run для simulation-modeling
#   bash fix_labs.sh apply                            # применить
#   BASE=/путь/к/labs bash fix_labs.sh apply          # другая копия репозитория
#   LABS="01 02" bash fix_labs.sh apply               # только выбранные лабы
set -uo pipefail

MODE="${1:-dry}"
BASE="${BASE:-$HOME/work/study/2026-1/2026-1==study-simulation-modeling/2026-1--study--simulation--modeling/labs}"
LABS="${LABS:-01 02 03 04 05 06 07 08}"
TS=$(date +%Y%m%d%H%M%S)

FONT_BLOCK='
%% Моноширинный шрифт с кириллицей (DejaVu Sans Mono)
\usepackage{fontspec}
\setmonofont{DejaVu Sans Mono}[Scale=MatchLowercase]'

# --- преобразования: читают stdin, пишут stdout ---

t_preamble() {
  local c
  c=$(cat)
  # закомментировать juliamono, если он подключён без %%
  c=$(sed -E 's/^([[:space:]]*)(\\usepackage\[[^]]*\]\{juliamono\})/\1%% \2/' <<<"$c")
  # добавить блок DejaVu, если его ещё нет
  if ! grep -q 'setmonofont{DejaVu Sans Mono}' <<<"$c"; then
    c="$c$FONT_BLOCK"
  fi
  printf '%s\n' "$c"
}

t_yaml() {
  local c
  c=$(cat)
  c=$(sed -E \
    -e 's/^# engine: julia$/engine: julia/' \
    -e 's/^# julia:$/julia:/' \
    -e 's/^#   exeflags:/  exeflags:/' \
    -e 's/^    # pdf-engine: xelatex$/    pdf-engine: xelatex/' <<<"$c")
  if ! grep -q 'monofont' <<<"$c"; then
    c=$(sed '/^  pdf:/a\    monofont: "DejaVu Sans Mono"' <<<"$c")
  fi
  printf '%s\n' "$c"
}

t_makefile() {
  local c
  c=$(cat)
  c=$(sed -E 's/^([[:space:]]*)-@quarto/\1quarto/' <<<"$c")
  if ! grep -q 'GKSwstype' <<<"$c"; then
    c="export GKSwstype = 100
$c"
  fi
  printf '%s\n' "$c"
}

# --- применение ---

apply_fix() {
  local f="$1" fn="$2" tmp
  [ -f "$f" ] || { echo "  $(basename "$f"): нет файла, пропуск"; return; }
  tmp=$(mktemp)
  "$fn" < "$f" > "$tmp"
  if cmp -s "$f" "$tmp"; then
    echo "  $(basename "$f"): без изменений"
  else
    echo "  $(basename "$f"): изменения:"
    diff "$f" "$tmp" | sed 's/^/      /' || true
    if [ "$MODE" = "apply" ]; then
      cp "$f" "$f.bak-$TS"
      cp "$tmp" "$f"
      echo "  -> применено, бэкап: $(basename "$f").bak-$TS"
    fi
  fi
  rm -f "$tmp"
}

check_yaml_exeflags() {
  local y="$1/_quarto.yml"
  if [ -f "$y" ] && ! grep -q '^  exeflags:' "$y"; then
    echo "  ВНИМАНИЕ: в _quarto.yml нет раскомментированного exeflags, проверьте вручную"
  fi
}

check_includes() {
  local R="$1" p ok=0 miss=0
  while read -r p; do
    if [ -f "$R/$p" ]; then
      ok=$((ok+1))
    else
      miss=$((miss+1))
      echo "  include MISSING: $p"
    fi
  done < <(grep -h -o '{{< include [^>]* >}}' "$R"/*report.qmd 2>/dev/null \
            | sed -E 's/.*\{\{< include //; s/ >\}\}//')
  echo "  include: найдено $ok, отсутствует $miss"
}

# --- основной цикл ---

echo "Каталог labs: $BASE"
for n in $LABS; do
  R="$BASE/lab$n/report"
  echo "=== lab$n ==="
  if [ ! -d "$R" ]; then
    echo "  нет $R, пропуск"
    continue
  fi
  apply_fix "$R/_resources/tex/preamble.tex" t_preamble
  apply_fix "$R/_quarto.yml" t_yaml
  apply_fix "$R/Makefile" t_makefile
  check_yaml_exeflags "$R"
  check_includes "$R"
done

echo
if [ "$MODE" = "apply" ]; then
  echo "Готово. Дальше в каждой папке report: make clean && make"
  echo "Отсутствующие include: проверьте project/markdown и поправьте путь в отчёте,"
  echo "либо сгенерируйте qmd через tangle.jl из соответствующего скрипта."
else
  echo "Dry-run. Для применения: BASE=... bash fix_labs.sh apply"
fi