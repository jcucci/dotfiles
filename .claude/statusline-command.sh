#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
model_name=$(echo "$input" | jq -r '.model.display_name')
usage=$(echo "$input" | jq '.context_window.current_usage')
context_window_size=$(echo "$input" | jq -r '.context_window.context_window_size')
model_id=$(echo "$input" | jq -r '.model.id')

# ANSI color codes
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# Initialize output parts
context_str=""
cost_str=""

# Calculate context percentage and cost if usage data is available
if [ "$usage" != "null" ]; then
  # Extract token counts
  input_tokens=$(echo "$usage" | jq -r '.input_tokens')
  output_tokens=$(echo "$usage" | jq -r '.output_tokens')
  cache_creation_tokens=$(echo "$usage" | jq -r '.cache_creation_input_tokens')
  cache_read_tokens=$(echo "$usage" | jq -r '.cache_read_input_tokens')

  # Calculate total current tokens (for context percentage)
  current_tokens=$((input_tokens + cache_creation_tokens + cache_read_tokens))

  # Calculate context percentage
  if [ "$context_window_size" != "null" ] && [ "$context_window_size" -gt 0 ]; then
    pct=$((current_tokens * 100 / context_window_size))

    # Choose color based on percentage
    if [ $pct -lt 50 ]; then
      context_color=$GREEN
    elif [ $pct -lt 80 ]; then
      context_color=$YELLOW
    else
      context_color=$RED
    fi

    context_str=$(printf " | ${context_color}%d%% context${RESET}" "$pct")
  fi

  # Calculate cost based on model
  case "$model_id" in
    *"claude-3-5-sonnet"*|*"claude-3-5-haiku"*)
      # Claude 3.5 Sonnet/Haiku pricing: $3/MTok input, $15/MTok output
      # Cache writes: $3.75/MTok, Cache reads: $0.30/MTok
      input_cost=$(echo "scale=6; $input_tokens * 3 / 1000000" | bc)
      output_cost=$(echo "scale=6; $output_tokens * 15 / 1000000" | bc)
      cache_write_cost=$(echo "scale=6; $cache_creation_tokens * 3.75 / 1000000" | bc)
      cache_read_cost=$(echo "scale=6; $cache_read_tokens * 0.30 / 1000000" | bc)
      ;;
    *"claude-opus-4"*)
      # Claude Opus 4/4.5 pricing: $15/MTok input, $75/MTok output
      # Cache writes: $18.75/MTok, Cache reads: $1.50/MTok
      input_cost=$(echo "scale=6; $input_tokens * 15 / 1000000" | bc)
      output_cost=$(echo "scale=6; $output_tokens * 75 / 1000000" | bc)
      cache_write_cost=$(echo "scale=6; $cache_creation_tokens * 18.75 / 1000000" | bc)
      cache_read_cost=$(echo "scale=6; $cache_read_tokens * 1.50 / 1000000" | bc)
      ;;
    *"claude-sonnet-4"*)
      # Claude Sonnet 4/4.5 pricing: $3/MTok input, $15/MTok output
      # Cache writes: $3.75/MTok, Cache reads: $0.30/MTok
      input_cost=$(echo "scale=6; $input_tokens * 3 / 1000000" | bc)
      output_cost=$(echo "scale=6; $output_tokens * 15 / 1000000" | bc)
      cache_write_cost=$(echo "scale=6; $cache_creation_tokens * 3.75 / 1000000" | bc)
      cache_read_cost=$(echo "scale=6; $cache_read_tokens * 0.30 / 1000000" | bc)
      ;;
    *)
      # Default pricing (use Sonnet pricing as fallback)
      input_cost=$(echo "scale=6; $input_tokens * 3 / 1000000" | bc)
      output_cost=$(echo "scale=6; $output_tokens * 15 / 1000000" | bc)
      cache_write_cost=$(echo "scale=6; $cache_creation_tokens * 3.75 / 1000000" | bc)
      cache_read_cost=$(echo "scale=6; $cache_read_tokens * 0.30 / 1000000" | bc)
      ;;
  esac

  # Sum up total cost
  total_cost=$(echo "scale=4; $input_cost + $output_cost + $cache_write_cost + $cache_read_cost" | bc)

  cost_str=$(printf " | ${GREEN}\$%.4f${RESET}" "$total_cost")
fi

# Output the status line
printf "${CYAN}%s${RESET}%s%s\n" "$model_name" "$context_str" "$cost_str"
