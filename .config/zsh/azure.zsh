# Helper function to select a resource group using fzf
azfzfgroup() {
    az group list --query "[].name" -o tsv | fzf --height 40% --prompt "Select Resource Group > "
}

# Helper function to select a web app using fzf
azfzfwebapp() {
    local resource_group=${1:-$(azfzfgroup)}
    if [ -z "$resource_group" ]; then
        echo "No resource group selected."
        return 1
    fi
    az webapp list --resource-group "$resource_group" --query "[].name" -o tsv | fzf --height 40% --prompt "Select Web App > "
}

# Helper function to select a storage account using fzf
azfzfstorage() {
    local resource_group=${1:-$(azfzfgroup)}
    if [ -z "$resource_group" ]; then
        echo "No resource group selected."
        return 1
    fi
    az storage account list --resource-group "$resource_group" --query "[].name" -o tsv | fzf --height 40% --prompt "Select Storage Account > "
}

# Helper function to select a SQL server using fzf
azfzfsqlserver() {
    local resource_group=${1:-$(azfzfgroup)}
    if [ -z "$resource_group" ]; then
        echo "No resource group selected."
        return 1
    fi
    az sql server list --resource-group "$resource_group" --query "[].name" -o tsv | fzf --height 40% --prompt "Select SQL Server > "
}

# Helper function to select a SQL database using fzf
azfzfsqldb() {
    local resource_group=${1:-$(azfzfgroup)}
    if [ -z "$resource_group" ]; then
        echo "No resource group selected."
        return 1
    fi
    
    local server_name=${2:-$(azfzfsqlserver "$resource_group")}
    if [ -z "$server_name" ]; then
        echo "No SQL server selected."
        return 1
    fi
    az sql db list --resource-group "$resource_group" --server "$server_name" --query "[].name" -o tsv | fzf --height 40% --prompt "Select SQL Database > "
}

# Helper function to select an AKS cluster using fzf
azfzfaks() {
    local resource_group=${1:-$(azfzfgroup)}
    if [ -z "$resource_group" ]; then
        echo "No resource group selected."
        return 1
    fi
    az aks list --resource-group "$resource_group" --query "[].name" -o tsv | fzf --height 40% --prompt "Select AKS Cluster > "
}

# Helper function to select a Function App using fzf
azfzffunc() {
    local resource_group=${1:-$(azfzfgroup)}
    if [ -z "$resource_group" ]; then
        echo "No resource group selected."
        return 1
    fi
    az functionapp list --resource-group "$resource_group" --query "[].name" -o tsv | fzf --height 40% --prompt "Select Function App > "
}

kvshow() {
    az keyvault secret show --vault-name king-ninja-sharp-kv -n $1
}

kvset() {
    az keyvault secret set --vault-name king-ninja-sharp-kv -n $1 --value $2
}

azvarshow() {
  az pipelines variable-group variable list --group-id 1 | jq --arg key "$1" '.[$key]'
}

azvarset() {
    az pipelines variable-group variable create --group-id 1 --name $1 --value $2
}

azstorage() {
    local resource_group=$(azfzfgroup)
    if [ -z "$resource_group" ]; then
        echo "No resource group selected."
        return 1
    fi
    local storage_name=$(azfzfstorage "$resource_group")
    if [ -z "$storage_name" ]; then
        echo "No storage account selected."
        return 1
    fi

    #az storage account show --resource-group "$resource_group" --name "$storage_name" --query "{Name:name, Location:location, Kind:kind}" -o table
    az storage account show --resource-group "$resource_group" --name "$storage_name" | jq '{name: .name, kind: .kind, location: .location, sku: .sku, status: .statusOfPrimary}'
}

azconnstr() {
    local resource_group=$(azfzfgroup)
    local storage_name=$(azfzfstorage "$resource_group")

    if [ -z "$resource_group" ]; then
        echo "No resource group selected."
        return 1
    fi

    if [ -z "$storage_name" ]; then
        echo "No storage account selected."
        return 1
    fi
    az storage account show-connection-string --resource-group "$resource_group" --name "$storage_name" --query "connectionString" -o tsv
}

azsql() {
    local resource_group=$(azfzfgroup)
    local sql_server=$(azfzfsqlserver "$resource_group")
    local sql_db=$(azfzfsqldb "$resource_group" "$sql_server")

    if [ -z "$resource_group" ]; then
        echo "No resource group selected."
        return 1
    fi

    if [ -z "$sql_server" ]; then
         echo "No SQL server selected."
        return 1
    fi
    
    if [ -z "$sql_db" ]; then
        echo "No SQL database selected."
        return 1
    fi

    az sql db show --resource-group "$resource_group" --server "$sql_server" --name "$sql_db" | jq '{collation: .coallation, sku: .currentSku, location: .location, name: .name, pool: .elasticPoolName, status: .status}'
}

azaks() {
    local resource_group=$(azfzfgroup)
    if [ -z "$resource_group" ]; then
        echo "No resource group selected."
        return 1
    fi
    
    local aks_cluster=$(azfzfaks "$resource_group")
    if [ -z "$aks_cluster" ]; then
        echo "No AKS cluster selected."
        return 1
    fi

    az aks show --resource-group "$resource_group" --name "$aks_cluster" | jq '{name: .name, location: .location, kubernetesVersion: .kubernetesVersion, powerState: .powerState}'
}

azakscred() {
    local resource_group=$(azfzfgroup)
    if [ -z "$resource_group" ]; then
        echo "No resource group selected."
        return 1
    fi

    local aks_cluster=$(azfzfaks "$resource_group")
    if [ -z "$aks_cluster" ]; then
        echo "No AKS cluster selected."
        return 1
    fi
    
    az aks get-credentials --resource-group "$resource_group" --name "$aks_cluster"
}

azfunc() {
    local resource_group=$(azfzfgroup)
    if [ -z "$resource_group" ]; then
        echo "No resource group selected."
        return 1
    fi
    
    local func_app=$(azfzffunc "$resource_group")
    if [ -z "$func_app" ]; then
        echo "No function app selected."
        return 1
    fi

    az functionapp show --resource-group "$resource_group" --name "$func_app" | jq '{hostName: .defaultHostName, kind: .kind, lastModified: .lastModifiedTimeUtc, location: .location, name: .name, runtime: .runtime, state: .state}'
}

aztriggers() {
    local resource_group=$(azfzfgroup)
    if [ -z "$resource_group" ]; then
        echo "No resource group selected."
        return 1
    fi
    
    local func_app=$(azfzffunc "$resource_group")

    if [ -z "$func_app" ]; then
        echo "No function app selected."
        return 1
    fi
    az functionapp function list --resource-group "$resource_group" --name "$func_app" | jq '[.[] | {runtime: .config.language, name: .config.name, id: id}]'
}

azsacc() {
    AZ_STORAGE_ACCOUNT=$(az storage account list --query "[].name" -o tsv | fzf --prompt="Select Storage Account: " --height=40% --border)
    echo "AZ_STORAGE_ACCOUNT: $AZ_STORAGE_ACCOUNT"
}

azscont() {
    AZ_STORAGE_CONTAINER=$(az storage container list --account-name $AZ_STORAGE_ACCOUNT --auth-mode login --query "[].name" -o tsv | fzf --prompt="Select Storage Container: " --height=40% --border)
    echo "AZ_STORAGE_CONTAINER: $AZ_STORAGE_CONTAINER"
}

azslist() {
    if [ -z "$1" ]; then
        az storage blob list \
            --account-name $AZ_STORAGE_ACCOUNT \
            --container $AZ_STORAGE_CONTAINER \
            --delimiter '/' \
            --query "[].name" \
            --auth-mode login \
            --output tsv
    else
        az storage blob list \
            --account-name $AZ_STORAGE_ACCOUNT \
            --container $AZ_STORAGE_CONTAINER \
            --prefix $1 \
            --delimiter '/' \
            --query "[].name" \
            --auth-mode login \
            --output tsv
    fi
}

azsorglist() {
    azslist "Organizations/$1/"
}

azsprojlist() {
    local projPath=$(azsorglist $1 | fzf --prompt="Select Projection Path:" --height=40% --border)

    if [ -z "$2" ]; then
        azslist "$projPath"
    else
        azslist "$projPath$2"
    fi
}

azsproj() {

    local projPath=$(azsorglist $1 | fzf --prompt="Select Projection Path:" --height=40% --border)
    if [ -z "$projPath" ]; then
        echo "No projection path selected."
        return 1
    fi

    local projName=$(basename $projPath)
    
    local blobList
    if [ -z "$2" ]; then
        blobList=$(azslist "$projPath")
    else
        blobList=$(azslist "$projPath$2")
    fi
    
    local blobPath=$(echo "$blobList" | fzf --prompt="Select Blob Path:" --height=40% --border)
    if [ -z "$blobPath" ]; then
        echo "No blob path selected."
        return 1
    fi

    local blobFileName=$(basename $blobPath)
    local destDir="$HOME/downloads/"

    if [ "$3" ]; then
        destDir="$HOME/documents/sharp/$3/"
        mkdir -p "$destDir"
    fi

    local destFile="$destDir$projName-$blobFileName"

    az storage blob download \
        --account-name $AZ_STORAGE_ACCOUNT \
        --container $AZ_STORAGE_CONTAINER \
        --file $destFile \
        --name $blobPath \
        --auth-mode login \
        --output none

    bat "$destFile"
}
