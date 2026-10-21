---
name: pipeline-patterns
description: Azure DevOps pipeline structure and patterns for .NET microservices
---

# Azure DevOps Pipeline Patterns

Reference for CI/CD pipeline configuration.

## Pipeline Structure

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
      - feature/*

pool:
  vmImage: 'ubuntu-latest'

stages:
  - stage: Build
    jobs:
      - job: BuildAndTest
        steps:
          - template: pipelines/build.yml
  
  - stage: Deploy
    dependsOn: Build
    condition: succeeded()
    jobs:
      - deployment: DeployToEnvironment
        environment: 'production'
        strategy:
          runOnce:
            deploy:
              steps:
                - template: pipelines/deploy.yml
```

## Build Template

```yaml
# pipelines/build.yml
parameters:
  - name: workingDirectory
  - name: azureContainerRegistry_azureSubscription
  - name: azureContainerRegistry

steps:
  # Restore NuGet packages
  - template: pipelines/shared/build_nuget_config.yml@arm

  # Build and run tests
  - task: DockerCompose@1
    displayName: Build tests
    inputs:
      containerregistrytype: Container Registry
      dockerComposeFile: docker-compose-unit-tests.yml
      action: Build services
      additionalImageTags: $(Build.SourceBranchName)-$(Build.BuildID)

  # Run unit tests
  - task: Bash@3
    displayName: Run unit tests
    inputs:
      targetType: inline
      script: |
        docker run --name $(Build.BuildID) image:tag
        docker cp $(Build.BuildID):/app/TestResults $(System.DefaultWorkingDirectory)
        docker container rm $(Build.BuildID)

  # Publish test results
  - task: PublishTestResults@2
    displayName: Publish Test Results
    inputs:
      testRunner: VSTest
      testResultsFiles: TestResults/**/*.trx
      failTaskOnFailedTests: true

  # Publish code coverage
  - task: PublishCodeCoverageResults@2
    displayName: Publish code coverage
    inputs:
      summaryFileLocation: $(System.DefaultWorkingDirectory)/TestResults/**/coverage.cobertura.xml
      failIfCoverageEmpty: true

  # Build Docker images
  - task: DockerCompose@1
    displayName: Build services
    inputs:
      containerregistrytype: Azure Container Registry
      azureSubscription: "${{ parameters.azureContainerRegistry_azureSubscription }}"
      azureContainerRegistry: "${{ parameters.azureContainerRegistry }}"
      dockerComposeFile: docker-compose.yml
      action: Build services
      additionalImageTags: $(Build.SourceBranchName)-$(Build.BuildID)

  # Push Docker images
  - task: DockerCompose@1
    displayName: Push services
    inputs:
      containerregistrytype: Azure Container Registry
      azureSubscription: "${{ parameters.azureContainerRegistry_azureSubscription }}"
      azureContainerRegistry: "${{ parameters.azureContainerRegistry }}"
      dockerComposeFile: docker-compose.yml
      action: Push services
      additionalImageTags: $(Build.SourceBranchName)-$(Build.BuildID)

  # Publish Azure Functions
  - task: DotNetCoreCLI@2
    displayName: Publish function
    inputs:
      command: publish
      publishWebProjects: false
      projects: src/az-functions/*/*.csproj
      arguments: --configuration release --output $(Build.ArtifactStagingDirectory)

  # Copy Kubernetes config
  - task: CopyFiles@2
    inputs:
      contents: "k8s-config/**"
      targetFolder: $(Build.ArtifactStagingDirectory)

  # Publish artifacts
  - task: PublishBuildArtifacts@1
    displayName: Publish Artifacts
    inputs:
      PathtoPublish: $(Build.ArtifactStagingDirectory)
      ArtifactName: drop
```

## Deploy Template

```yaml
# pipelines/deploy.yml
parameters:
  - name: environment
  - name: azureSubscription
  - name: aksCluster
  - name: aksResourceGroup

steps:
  # Download artifacts
  - download: current
    artifact: drop

  # Deploy Helm chart
  - task: HelmDeploy@0
    displayName: Deploy Helm chart
    inputs:
      connectionType: Azure Resource Manager
      azureSubscription: ${{ parameters.azureSubscription }}
      azureResourceGroup: ${{ parameters.aksResourceGroup }}
      kubernetesCluster: ${{ parameters.aksCluster }}
      namespace: app-namespace
      command: upgrade
      chartType: FilePath
      chartPath: $(Pipeline.Workspace)/drop/k8s-config/helm-app
      releaseName: app-release
      overrideValues: imageTag=$(Build.BuildId)
      install: true
      waitForExecution: true

  # Deploy Azure Functions
  - task: AzureFunctionApp@1
    displayName: Deploy Function App
    inputs:
      azureSubscription: ${{ parameters.azureSubscription }}
      appType: functionApp
      appName: $(functionAppName)
      package: $(Pipeline.Workspace)/drop/*.zip
```

## Environment-Specific Pipelines

```yaml
# pipelines/team_pipeline.yml (Development)
trigger:
  branches:
    include:
      - feature/*

variables:
  - group: team-variables

stages:
  - template: build.yml
  - template: deploy.yml
    parameters:
      environment: team
```

```yaml
# pipelines/prod_pipeline.yml (Production)
trigger:
  branches:
    include:
      - main

variables:
  - group: prod-variables

stages:
  - template: build.yml
  - template: deploy.yml
    parameters:
      environment: production
```

## Variable Groups

```yaml
# Reference variable groups
variables:
  - group: common-variables
  - group: environment-specific-variables
  - name: localVariable
    value: 'value'
```

## Conditions

```yaml
# Run only on main branch
condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))

# Run only if previous stage succeeded
condition: succeeded()

# Skip for PRs
condition: ne(variables['Build.Reason'], 'PullRequest')
```

## Common Tasks

### .NET Build
```yaml
- task: DotNetCoreCLI@2
  inputs:
    command: build
    projects: '**/*.csproj'
    arguments: '--configuration Release'
```

### .NET Test
```yaml
- task: DotNetCoreCLI@2
  inputs:
    command: test
    projects: '**/*Tests.csproj'
    arguments: '--configuration Release --collect:"XPlat Code Coverage"'
```

### Docker Build
```yaml
- task: Docker@2
  inputs:
    containerRegistry: 'registry-connection'
    repository: 'app/service'
    command: buildAndPush
    Dockerfile: '**/Dockerfile'
    tags: |
      $(Build.BuildId)
      latest
```

### Helm Deploy
```yaml
- task: HelmDeploy@0
  inputs:
    command: upgrade
    chartType: FilePath
    chartPath: './charts/app'
    releaseName: 'app-release'
    overrideValues: 'image.tag=$(Build.BuildId)'
```

## Best Practices

1. **Use templates** for reusable steps
2. **Separate build and deploy** stages
3. **Use variable groups** for secrets
4. **Tag images** with build ID
5. **Fail fast** on test failures
6. **Publish artifacts** for traceability
7. **Use environments** for approvals
8. **Version Helm charts** appropriately
