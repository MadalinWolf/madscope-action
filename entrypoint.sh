#!/bin/bash
# MadScope GitHub Action entrypoint. Maps action inputs to the real
# `madscope` CLI (same engine as the desktop app) and exposes the
# machine-readable result as step outputs.
set -uo pipefail

cd "${INPUT_WORKING_DIRECTORY:-$GITHUB_WORKSPACE}"

ARGS=("$INPUT_COMMAND" "$INPUT_URL")
if [ -n "${INPUT_VIEWPORTS:-}" ]; then
  # shellcheck disable=SC2206
  ARGS+=(--viewport ${INPUT_VIEWPORTS})
fi
if [ -n "${INPUT_THRESHOLD:-}" ]; then
  ARGS+=(--threshold "$INPUT_THRESHOLD")
fi
if [ "${INPUT_FULL_PAGE:-false}" = "true" ]; then
  ARGS+=(--full-page)
fi

CODE=0
if [ "$INPUT_COMMAND" = "test" ]; then
  # Machine-readable report for outputs; also saved for artifact upload.
  OUT=$(node /madscope/apps/cli/dist/index.js "${ARGS[@]}" --json | tee madscope-report.json) || CODE=$?
  REPORT_REL=$(node -e "console.log(require('path').relative(process.env.GITHUB_WORKSPACE, process.cwd() + '/madscope-report.json'))")
  {
    echo "passed=$(echo "$OUT" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{try{console.log(JSON.parse(d).passed)}catch{console.log('false')}})")"
    echo "max_change_ratio=$(echo "$OUT" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{try{const r=JSON.parse(d);const m=Math.max(0,...r.cases.map(c=>c.changeRatio??0));console.log(m)}catch{console.log('')}})")"
    echo "report=$REPORT_REL"
  } >> "$GITHUB_OUTPUT"
else
  node /madscope/apps/cli/dist/index.js "${ARGS[@]}" || CODE=$?
  echo "passed=$([ "$CODE" -eq 0 ] && echo true || echo false)" >> "$GITHUB_OUTPUT"
fi

exit "$CODE"
