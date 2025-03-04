alias dnpack='dotnet pack -c RELEASE'

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
        jq --arg pkg "$package_name" '.data[] | select(.id | ascii_downcase == ($pkg | ascii_downcase)) | {name: .id, versions: (.versions | sort_by(.) | reverse | .[0:5])}'
    else
        curl -s "https://api-v2v3search-0.nuget.org/query?q=$package_name&prerelease=false" | \
        jq --arg pkg "$package_name" '.data[] | select(.id | ascii_downcase == ($pkg | ascii_downcase)) | {name: .id, versions: (.versions | sort_by(.) | reverse | .[0:5])}'
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
