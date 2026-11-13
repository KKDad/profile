#!/usr/bin/env bash

status_json=$(cat)

IFS=$'\t' read -r model effort cwd session_cost context_tokens context_size session_id cache_expires_at cache_warm cache_ttl < <(jq -r '[
  .model.display_name,
  (.effort | if type == "object" then (.level // .name // "-") else (. // "-") end),
  .workspace.current_dir,
  (.cost.total_cost_usd // 0),
  (.context_window.current_usage | (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)),
  (.context_window.context_window_size // 0),
  (.session_id // "-"),
  (.prompt_cache.expires_at // "-"),
  (.prompt_cache.warm // "-"),
  (.prompt_cache.ttl // "-")
] | @tsv' <<< "$status_json")
[[ "$session_id" == "-" ]] && session_id=""

guardrails_dir="$HOME/ai-guardrails"

if [[ "$effort" == "-" && -n "$session_id" ]]; then
  effort=$(jq -r '.effort // "-"' "$guardrails_dir/session-cost/$session_id.json" 2>/dev/null || echo "-")
fi
model_label="$model"
[[ -n "$effort" && "$effort" != "-" ]] && model_label="$model ($effort)"

context_label=$(awk -v used="$context_tokens" -v size="$context_size" '
  function human(tokens) {
    if (tokens >= 1000000) { value = sprintf("%.1f", tokens / 1000000); unit = "m" }
    else if (tokens >= 1000) { value = sprintf("%.1f", tokens / 1000); unit = "k" }
    else return tokens
    sub(/\.0$/, "", value)
    return value unit
  }
  BEGIN { printf "%s/%s tokens (%d%%)", human(used), human(size), (size > 0 ? int(used * 100 / size + 0.5) : 0) }')

context_circle=$(awk -v used="$context_tokens" 'BEGIN { print (used > 400000 ? "🔴" : (used > 300000 ? "🟡" : "🟢")) }')

git_info=""
if git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null); then
  git_info=$(printf " \033[36m(%s)" "$git_branch")
  [[ -n $(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null) ]] && git_info+=$(printf "\033[31m*")
fi

today_total=$(jq -rs --arg day "$(date +%Y-%m-%d)" \
  '[.[] | select(.day == $day) | (.cost_usd // 0) - (.day_start_usd // 0)] | add // 0' \
  "$guardrails_dir"/session-cost/*.json 2>/dev/null || echo 0)
today_total=${today_total:-0}

read -r month_spent month_limit < <(jq -r 'if .failed == false and .spend.used_minor != null
  then [(.spend.used_minor / pow(10; .spend.exponent // 2)), ((.spend.limit_minor // 0) / pow(10; .spend.exponent // 2))] | @tsv
  else "-1\t0" end' "$guardrails_dir/account-spend.json" 2>/dev/null || echo "-1 0")
month_spent=${month_spent:--1}
month_limit=${month_limit:-0}

read -r weekdays_left burn_arrow < <(awk -v dom="$(date +%-d)" -v dim="$(date -j -v1d -v+1m -v-1d +%d)" -v first="$(date -j -v1d +%u)" \
  -v spent="$month_spent" -v limit="$month_limit" -v fallback_budget="${CLAUDE_MONTHLY_BUDGET:-1000}" '
  BEGIN {
    for (day = 1; day <= dim; day++) {
      if ((first + day - 2) % 7 >= 5) continue
      total++
      if (day <= dom) elapsed++
      if (day >= dom) remaining++
    }
    budget = limit > 0 ? limit : fallback_budget
    projected = elapsed > 0 ? spent * total / elapsed : spent
    arrow = spent < 0 ? "?" : (projected > budget ? "↑" : "↓")
    printf "%d %s\n", remaining, arrow
  }')
day_word="days"
(( weekdays_left == 1 )) && day_word="day"

preflight=$("$HOME/.claude/scripts/preflight.sh" statusline < /dev/null 2>/dev/null)

cache_segment=""
if [[ "$cache_expires_at" != "-" ]]; then
  cache_segment=$(awk -v expires="$cache_expires_at" -v now="$(date +%s)" -v warm="$cache_warm" -v ttl="$cache_ttl" 'BEGIN {
    ttl_seconds = (ttl ~ /h$/ ? substr(ttl, 1, length(ttl) - 1) * 3600 : (ttl ~ /m$/ ? substr(ttl, 1, length(ttl) - 1) * 60 : 3600))
    remaining = expires - now
    if (warm != "true" || remaining <= 0) { printf "\033[31m🚨 cache cold\033[0m"; exit }
    if (remaining >= 120) label = sprintf("%dm", remaining / 60)
    else if (remaining >= 60) label = sprintf("%dm %ds", remaining / 60, remaining % 60)
    else label = sprintf("%ds", remaining)
    if (remaining < 300 || remaining < ttl_seconds / 5) { icon = "🚨"; color = "31" }
    else if (remaining < ttl_seconds / 2) { icon = "⏰"; color = "33" }
    else { icon = "⏳"; color = "32" }
    printf "\033[%sm%s %s\033[0m", color, icon, label
  }')
fi

month_label='$?'
awk -v spent="$month_spent" 'BEGIN { exit !(spent >= 0) }' && month_label=$(printf '$%.2f' "$month_spent")

printf "\033[35m%s \033[38;2;175;135;255m%s\033[0m %s \033[32m%s@%s \033[33m%s%s\033[0m  %s  \033[94m\$%.2f/\$%.2f/%s · %s %s%s\033[0m %s" \
  "$model_label" "$context_label" "$context_circle" "$USER" "$(hostname -s)" "${cwd/#$HOME/~}" "$git_info" "$preflight" \
  "$session_cost" "$today_total" "$month_label" "$weekdays_left" "$day_word" "$burn_arrow" "$cache_segment"
