# Infrastructure Deployment

## Azure Verified Modules (AVM) Migration

This Bicep template has been updated to leverage Azure Verified Modules (AVM) from the public Bicep registry. AVM provides enterprise-grade, pre-validated, and maintained Bicep modules that follow Microsoft best practices.

### What are Azure Verified Modules?

Azure Verified Modules are a curated set of pre-built Bicep/Terraform modules that:
- Follow Microsoft's best practices and design patterns
- Are thoroughly tested and validated by Microsoft
- Receive regular updates and security patches
- Provide consistent interfaces across all modules
- Include built-in support for diagnostics, RBAC, and other enterprise features

Learn more: https://aka.ms/avm

### Resources Migrated to AVM

The following resources now use Azure Verified Modules:

| Resource | AVM Module | Version |
|----------|-----------|---------|
| Cosmos DB | `avm/res/document-db/database-account` | 0.9.0 |
| Storage Account | `avm/res/storage/storage-account` | 0.14.3 |
| AI Search Service | `avm/res/search/search-service` | 0.9.0 |
| Log Analytics Workspace | `avm/res/operational-insights/workspace` | 0.9.1 |
| Application Insights | `avm/res/insights/component` | 0.5.0 |
| Container Registry | `avm/res/container-registry/registry` | 0.7.0 |
| App Service Plan | `avm/res/web/serverfarm` | 0.4.0 |
| App Service (Web App) | `avm/res/web/site` | 0.12.0 |

### Resources Using Native Bicep

The following resources continue to use native Bicep resource declarations as there are no stable AVM modules available yet:

- **AI Foundry (Cognitive Services)**: Uses preview API version and specialized configuration for AI Foundry project management

### Benefits of This Migration

1. **Best Practices**: All modules follow Microsoft's Well-Architected Framework
2. **Security**: Built-in security configurations and regular security updates
3. **Maintainability**: Standardized interfaces make it easier to update and maintain
4. **Features**: Access to advanced features like diagnostic settings, private endpoints, and RBAC without additional code
5. **Future-Proof**: Modules are maintained and updated by Microsoft as Azure evolves

### Deployment

The deployment process remains the same:

```bash
# Using Azure CLI
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file DeployAzureResources.bicep
```

Or deploy via Visual Studio Code with the Bicep extension as described in the workshop documentation.

### Module Registry

All AVM modules are sourced from the public Bicep registry: `br/public:avm/...`

The registry automatically resolves to `mcr.microsoft.com/bicep/avm/...` and ensures you're using verified, signed modules from Microsoft.

### Further Reading

- [Azure Verified Modules Documentation](https://aka.ms/avm)
- [Bicep Registry](https://aka.ms/bicep/registry)
- [AVM Module Index](https://azure.github.io/Azure-Verified-Modules/)
- [AVM on GitHub](https://github.com/Azure/bicep-registry-modules)

### Key Changes from Original Template

#### Before (Native Bicep Resources)
```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}
```

#### After (AVM Module)
```bicep
module storageAccount 'br/public:avm/res/storage/storage-account:0.14.3' = {
  name: '${uniqueString(deployment().name, location)}-storage'
  params: {
    name: storageAccountName
    location: location
    skuName: 'Standard_LRS'
    kind: 'StorageV2'
    accessTier: 'Hot'
  }
}
```

**Benefits:**
- Cleaner parameter structure
- Built-in diagnostic settings support
- Consistent output interface
- Regular security and feature updates
- RBAC role assignments support

### Validation

To validate the Bicep file before deployment:

```bash
az bicep build --file DeployAzureResources.bicep
```

Note: This requires network connectivity to download the AVM modules from the Microsoft Container Registry.
