alias dnpack='dotnet pack -c RELEASE'
alias csr='csharprepl --useTerminalPaletteTheme'

dntest() {
    dotnet test $1 -v q --nologo --filter=Category!=Integration
}

dnbuild() {
    dotnet build $1 -v q --nologo
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
        
        curl -s \
        --header "Accept: application/json" \
        --header "Authorization: Basic $(echo -n ":$AZURE_DEVOPS_PAT" | base64 -w 0)" \
        "https://sharpfm.pkgs.visualstudio.com/_packaging/64eacba0-4a33-4524-a207-22b9304801fa/nuget/v3/query2/?q=$package_name&prerelease=false" | \
        jq --arg pkg "$package_name" '.data[] | select(.id | ascii_downcase == ($pkg | ascii_downcase)) | {name: .id, versions: (.versions | sort_by(.) | reverse | .[0:8])}'
    else
        curl -s "https://api-v2v3search-0.nuget.org/query?q=$package_name&prerelease=false" | \
        jq --arg pkg "$package_name" '.data[] | select(.id | ascii_downcase == ($pkg | ascii_downcase)) | {name: .id, versions: (.versions | sort_by(.) | reverse | .[0:8])}'
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
        
        curl -s \
        --header "Accept: application/json" \
        --header "Authorization: Basic $(echo -n ":$AZURE_DEVOPS_PAT" | base64 -w 0)" \
        "https://sharpfm.pkgs.visualstudio.com/_packaging/64eacba0-4a33-4524-a207-22b9304801fa/nuget/v3/query2/?q=$package_name&prerelease=true" | \
        jq '[.data[] | {name: .id, version: .version}]'
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
    
    if [ -z "$1" ]; then
        echo "Usage: dncover <solution_or_project_path>"
        echo "  Runs dotnet test with code coverage collection and generates HTML report"
        echo "  Excludes integration tests and opens coverage report in browser"
        return 1
    fi
    
    if [ ! -f "$1" ] && [ ! -d "$1" ]; then
        echo "Error: Path '$1' does not exist"
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
    dotnet test "$1" -v q --nologo --filter=Category!=Integration --collect:"XPlat Code Coverage" --results-directory:"./$coverage_dir"
    
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
