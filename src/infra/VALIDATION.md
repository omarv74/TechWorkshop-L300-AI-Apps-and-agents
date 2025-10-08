# Deployment Validation Checklist

Use this checklist to validate the AVM-based Bicep deployment.

## Pre-Deployment Validation

- [ ] **Bicep CLI Version**: Ensure you have Bicep CLI 0.20.0 or later
  ```bash
  az bicep version
  ```

- [ ] **Network Connectivity**: Verify access to Microsoft Container Registry
  ```bash
  curl -I https://mcr.microsoft.com
  ```

- [ ] **Build Validation**: Compile the Bicep file to check for syntax errors
  ```bash
  cd src/infra
  az bicep build --file DeployAzureResources.bicep
  ```

- [ ] **Resource Group**: Create or identify the target resource group
  ```bash
  az group create --name <rg-name> --location eastus2
  ```

## Deployment

- [ ] **Deploy Template**: Execute the deployment
  ```bash
  az deployment group create \
    --resource-group <rg-name> \
    --template-file DeployAzureResources.bicep \
    --verbose
  ```

- [ ] **Monitor Progress**: Watch deployment in Azure Portal
  - Navigate to Resource Group > Deployments
  - Monitor each module deployment

## Post-Deployment Validation

### Resource Validation

- [ ] **Cosmos DB Account**: Verify account is created
  ```bash
  az cosmosdb show --name <cosmos-db-name> --resource-group <rg-name>
  ```

- [ ] **Cosmos DB Database**: Verify database exists
  ```bash
  az cosmosdb sql database show \
    --account-name <cosmos-db-name> \
    --name zava \
    --resource-group <rg-name>
  ```

- [ ] **Storage Account**: Verify storage account is created
  ```bash
  az storage account show --name <storage-name> --resource-group <rg-name>
  ```

- [ ] **AI Search Service**: Verify search service is created
  ```bash
  az search service show --name <search-name> --resource-group <rg-name>
  ```

- [ ] **Log Analytics Workspace**: Verify workspace is created
  ```bash
  az monitor log-analytics workspace show \
    --workspace-name <workspace-name> \
    --resource-group <rg-name>
  ```

- [ ] **Application Insights**: Verify App Insights is created
  ```bash
  az monitor app-insights component show \
    --app <app-insights-name> \
    --resource-group <rg-name>
  ```

- [ ] **Container Registry**: Verify ACR is created
  ```bash
  az acr show --name <registry-name> --resource-group <rg-name>
  ```

- [ ] **App Service Plan**: Verify plan is created
  ```bash
  az appservice plan show --name <plan-name> --resource-group <rg-name>
  ```

- [ ] **App Service**: Verify web app is created
  ```bash
  az webapp show --name <app-name> --resource-group <rg-name>
  ```

- [ ] **AI Foundry**: Verify cognitive services account is created
  ```bash
  az cognitiveservices account show \
    --name <ai-foundry-name> \
    --resource-group <rg-name>
  ```

### Output Validation

- [ ] **Deployment Outputs**: Verify all outputs are returned correctly
  ```bash
  az deployment group show \
    --name <deployment-name> \
    --resource-group <rg-name> \
    --query properties.outputs
  ```

Expected outputs:
- `cosmosDbEndpoint`: Cosmos DB endpoint URL
- `storageAccountName`: Storage account name
- `searchServiceName`: Search service name
- `container_registry_name`: Container registry name
- `application_name`: Web app name
- `application_url`: Web app URL

### Configuration Validation

- [ ] **Cosmos DB Configuration**:
  - Consistency level: Session
  - Failover location: Primary location
  - Local auth: Disabled

- [ ] **Storage Account Configuration**:
  - SKU: Standard_LRS
  - Kind: StorageV2
  - Access tier: Hot

- [ ] **App Service Configuration**:
  - HTTPS only: Enabled
  - Docker configuration: Set
  - App Insights integration: Enabled

### Module-Specific Features

- [ ] **Diagnostic Settings**: Check if diagnostic settings are configured (AVM feature)
  ```bash
  az monitor diagnostic-settings list \
    --resource <resource-id>
  ```

- [ ] **RBAC**: Verify RBAC assignments if configured
  ```bash
  az role assignment list \
    --scope <resource-id>
  ```

## Functional Testing

- [ ] **Application Deployment**: Deploy application container to App Service
- [ ] **Application Access**: Test accessing the application URL
- [ ] **Cosmos DB Connectivity**: Test application can connect to Cosmos DB
- [ ] **Storage Access**: Test application can access Storage Account
- [ ] **AI Search**: Test search functionality
- [ ] **Application Insights**: Verify telemetry is being collected

## Comparison with Previous Deployment

If you have a previous deployment with native Bicep:

- [ ] **Resource Parity**: All resources from old deployment exist in new deployment
- [ ] **Configuration Match**: Resource configurations match
- [ ] **Output Compatibility**: Outputs have same values/format
- [ ] **Application Function**: Application works identically

## Cleanup (Optional)

If this was a test deployment:

- [ ] **Delete Resource Group**:
  ```bash
  az group delete --name <rg-name> --yes --no-wait
  ```

## Troubleshooting

### Common Issues

**Issue**: Module download fails
- **Solution**: Check network connectivity to mcr.microsoft.com
- **Solution**: Verify Bicep CLI version (should be 0.20.0+)

**Issue**: Parameter validation errors
- **Solution**: Check parameter names match AVM module expectations
- **Solution**: Review module documentation for required parameters

**Issue**: Deployment timeout
- **Solution**: Check Azure service health
- **Solution**: Verify resource quotas in subscription

**Issue**: Resource conflicts
- **Solution**: Ensure resource names are unique
- **Solution**: Delete conflicting resources or use different names

## Notes

- First-time deployment may take 15-20 minutes
- AVM modules download on first use (cached thereafter)
- Some resources may take additional time to fully provision
- Monitor Azure Portal for detailed deployment progress

## Support

- [Azure Verified Modules Documentation](https://aka.ms/avm)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Support](https://azure.microsoft.com/support/)
