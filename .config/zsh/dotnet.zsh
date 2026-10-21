alias dnpack='dotnet pack -c RELEASE'
alias csr='csharprepl --useTerminalPaletteTheme'

_sharpfm_curl() {
    local url="$1"
    local response http_code body msg
    response=$(curl -s -w $'\n%{http_code}' \
        --header "Accept: application/json" \
        --header "Authorization: Basic $(echo -n ":$AZURE_DEVOPS_PAT" | base64 -w 0)" \
        "$url")
    http_code="${response##*$'\n'}"
    body="${response%$'\n'*}"

    if [ "$http_code" = "200" ]; then
        printf '%s' "$body"
        return 0
    fi

    if echo "$body" | grep -q "Personal Access Token used has expired"; then
        echo "Error: AZURE_DEVOPS_PAT has expired. Refresh it in ~/.config/zsh/dev.env and re-source your shell." >&2
    else
        msg=$(echo "$body" | jq -r '.message // empty' 2>/dev/null)
        echo "Error: sharpfm feed returned HTTP $http_code${msg:+: $msg}" >&2
    fi
    return 1
}

_dn_find_solution() {
    local solutions=()

    # Search current directory (non-recursive)
    solutions+=(*.sln(N) *.slnx(N))

    # Search src/ directory if it exists
    if [[ -d "src" ]]; then
        solutions+=(src/*.sln(N) src/*.slnx(N))
    fi

    # If none found, return error
    if [[ ${#solutions[@]} -eq 0 ]]; then
        echo "Error: No solution file found in current directory or src/" >&2
        return 1
    fi

    # If exactly one, return it
    if [[ ${#solutions[@]} -eq 1 ]]; then
        echo "${solutions[1]}"
        return 0
    fi

    # Multiple found - filter out Api.Tests
    local filtered=()
    for sln in "${solutions[@]}"; do
        if [[ ! "$sln" == *"Api.Tests"* ]]; then
            filtered+=("$sln")
        fi
    done

    # If filtering leaves exactly one, use it
    if [[ ${#filtered[@]} -eq 1 ]]; then
        echo "${filtered[1]}"
        return 0
    fi

    # If all were filtered out, fall back to original list
    if [[ ${#filtered[@]} -eq 0 ]]; then
        filtered=("${solutions[@]}")
    fi

    # Multiple remain - interactive prompt
    echo "Multiple solution files found:" >&2
    local i=1
    for sln in "${filtered[@]}"; do
        echo "  $i) $sln" >&2
        ((i++))
    done

    echo -n "Select [1-${#filtered[@]}]: " >&2
    read choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#filtered[@]} ]]; then
        echo "${filtered[$choice]}"
        return 0
    else
        echo "Invalid selection" >&2
        return 1
    fi
}

dntest() {
    local target="$1"
    if [[ -z "$target" ]]; then
        target=$(_dn_find_solution) || return 1
    fi
    dotnet test "$target" -v q --nologo --filter=Category!=Integration
}

dnbuild() {
    local target="$1"
    if [[ -z "$target" ]]; then
        target=$(_dn_find_solution) || return 1
    fi
    dotnet build "$target" -v q --nologo
}

dnpush() {
    dotnet nuget push $1 -s "sharpfm" -k az
}

dnversions() {
    if [ -z "$1" ] && [ -z "$2" ]; then
        echo "Usage: dnversions <package_name> [sharpfm] or dnversions [sharpfm] <package_name>"
        return 1
    fi
    
    local package_name
    local is_sharpfm=false
    
    if [ "$1" = "sharpfm" ]; then
        is_sharpfm=true
        package_name="$2"
    elif [ "$2" = "sharpfm" ]; then
        is_sharpfm=true
        package_name="$1"
    else
        package_name="$1"
    fi
    
    if [ -z "$package_name" ]; then
        echo "Error: Package name is required"
        return 1
    fi
    
    if [ "$is_sharpfm" = true ]; then
        if [ -z "$AZURE_DEVOPS_PAT" ]; then
            echo "Error: AZURE_DEVOPS_PAT environment variable not set"
            return 1
        fi

        local body
        body=$(_sharpfm_curl "https://sharpfm.pkgs.visualstudio.com/_packaging/64eacba0-4a33-4524-a207-22b9304801fa/nuget/v3/query2/?q=$package_name&prerelease=false") || return 1
        echo "$body" | jq --arg pkg "$package_name" '.data[] | select(.id | ascii_downcase == ($pkg | ascii_downcase)) | {name: .id, versions: (.versions | map(.version) | sort_by(split(".") | map(tonumber? // .)) | reverse | .[0:8])}'
    else
        curl -s "https://api-v2v3search-0.nuget.org/query?q=$package_name&prerelease=false" | \
        jq --arg pkg "$package_name" '.data[] | select(.id | ascii_downcase == ($pkg | ascii_downcase)) | {name: .id, versions: (.versions | map(.version) | sort_by(split(".") | map(tonumber? // .)) | reverse | .[0:8])}'
    fi
}

dnsearch() {
    if [ -z "$1" ] && [ -z "$2" ]; then
        echo "Usage: nuget_search <package_name> [sharpfm] or nuget_search [sharpfm] <package_name>"
        return 1
    fi
    
    local package_name
    local is_sharpfm=false
    
    if [ "$1" = "sharpfm" ]; then
        is_sharpfm=true
        package_name="$2"
    elif [ "$2" = "sharpfm" ]; then
        is_sharpfm=true
        package_name="$1"
    else
        package_name="$1"
    fi
    
    if [ -z "$package_name" ]; then
        echo "Error: Package name is required"
        return 1
    fi
    
    if [ "$is_sharpfm" = true ]; then
        if [ -z "$AZURE_DEVOPS_PAT" ]; then
            echo "Error: AZURE_DEVOPS_PAT environment variable not set"
            return 1
        fi

        local body
        body=$(_sharpfm_curl "https://sharpfm.pkgs.visualstudio.com/_packaging/64eacba0-4a33-4524-a207-22b9304801fa/nuget/v3/query2/?q=$package_name&prerelease=true") || return 1
        echo "$body" | jq '[.data[] | {name: .id, version: .version}]'
    else
        # Public NuGet search
        curl -s "https://api-v2v3search-0.nuget.org/query?q=$package_name&prerelease=false" | \
        jq '[.data[] | {name: .id, version: .version}]'
    fi
}

dncover() {
    # Check if reportgenerator tool is available, install if not
    command -v reportgenerator >/dev/null || { echo "Installing reportgenerator..."; dotnet tool install -g dotnet-reportgenerator-globaltool; }

    if [ $? -ne 0 ]; then
        echo "Error: Failed to install reportgenerator tool"
        return 1
    fi

    local target="$1"
    if [[ -z "$target" ]]; then
        target=$(_dn_find_solution) || return 1
    elif [ ! -f "$target" ] && [ ! -d "$target" ]; then
        echo "Error: Path '$target' does not exist"
        return 1
    fi

    local coverage_dir=".coverage"
    
    echo "Setting up coverage directory..."
    if [ -d "$coverage_dir" ]; then
        rm -rf "$coverage_dir"/*
    else
        mkdir "$coverage_dir"
    fi
    
    echo "Running tests with code coverage..."
    dotnet test "$target" -v q --nologo --filter=Category!=Integration --collect:"XPlat Code Coverage" --results-directory:"./$coverage_dir"
    
    if [ $? -ne 0 ]; then
        echo "Error: Test execution failed"
        return 1
    fi
    
    echo "Generating HTML coverage report..."
    reportgenerator -reports:"./$coverage_dir/**/coverage.cobertura.xml" -targetdir:"$coverage_dir" -reporttypes:Html -verbosity:Off
    
    if [ $? -ne 0 ]; then
        echo "Error: Coverage report generation failed"
        echo "Make sure 'reportgenerator' is installed (dotnet tool install -g dotnet-reportgenerator-globaltool)"
        return 1
    fi
    
    echo "Opening coverage report in browser..."
    xdg-open "$coverage_dir/index.htm" >/dev/null 2>&1
    
    echo "Coverage report generated successfully at: $coverage_dir/index.htm"

    # Wait a moment for the browser to open
    sleep 1
    
    # Try multiple possible window title patterns
    local workspace=$(hyprctl clients -j | jq -r '.[] | select(.title | contains("Coverage Report") or contains("index.htm") or contains("coverage")) | .workspace.id' | head -1)
    
    if [ -n "$workspace" ] && [ "$workspace" != "null" ]; then
        echo "Browser workspace found: $workspace"
        hyprctl dispatch workspace $workspace
    else
        echo "Could not find coverage report browser window automatically"
        echo "You may need to manually switch to the browser workspace"
    fi
}

dnupdate() {
    echo "Updating all .NET tools..."
    
    # Get list of installed tools
    local tools=$(dotnet tool list -g --format json | jq -r '.data[] | .packageId')
    
    if [ -z "$tools" ]; then
        echo "No .NET tools installed globally"
        return 0
    fi
    
    echo "Found $(echo "$tools" | wc -l) installed tools:"
    echo "$tools" | sed 's/^/  - /'
    echo ""
    
    # Update each tool
    local updated_count=0
    local failed_count=0
    
    while IFS= read -r tool; do
        if [ -n "$tool" ]; then
            echo "Updating $tool..."
            if dotnet tool update -g "$tool" >/dev/null 2>&1; then
                echo "  ✓ Updated $tool"
                ((updated_count++))
            else
                echo "  ✗ Failed to update $tool"
                ((failed_count++))
            fi
        fi
    done <<< "$tools"
    
    echo ""
    echo "Update complete:"
    echo "  - Updated: $updated_count"
    echo "  - Failed: $failed_count"
    
    if [ $failed_count -gt 0 ]; then
        return 1
    fi
}

dnoutdated() {
  echo "Updating all .NET package references"

  dotnet outdated -u:Prompt $1
}
