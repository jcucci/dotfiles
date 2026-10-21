---
name: create-repository
description: Guide for creating Cosmos DB or Blob Storage repository implementations
---

# Creating a Repository

This skill covers both Cosmos DB and Blob Storage repository patterns.

## Cosmos DB Repository

### Interface
```csharp
public interface IEntityRepository
{
    Task<Entity?> GetAsync(Guid organizationId, Guid entityId);
    Task<IEnumerable<Entity>> GetByPatientAsync(Guid organizationId, Guid patientId);
    Task SaveAsync(Entity entity);
    Task DeleteAsync(Guid organizationId, Guid entityId);
    Task<bool> ExistsAsync(Guid organizationId, Guid entityId);
}
```

### Implementation
```csharp
public class EntityRepository : IEntityRepository
{
    private readonly ICosmosRepository _cosmosRepository;

    public EntityRepository(ICosmosRepository cosmosRepository)
    {
        _cosmosRepository = cosmosRepository;
    }

    public async Task<Entity?> GetAsync(Guid organizationId, Guid entityId)
    {
        var partition = BuildPartition(organizationId);
        return await _cosmosRepository.ReadDocumentByIdAsync<Entity>(
            partition, 
            entityId.ToString());
    }

    public async Task<IEnumerable<Entity>> GetByPatientAsync(
        Guid organizationId, 
        Guid patientId)
    {
        var partition = BuildPartition(organizationId);
        var iterator = await _cosmosRepository.QueryDocumentsAsync<Entity>(
            partition,
            e => e.PatientId == patientId);
        
        var results = new List<Entity>();
        while (iterator.HasMoreResults)
        {
            var response = await iterator.ReadNextAsync();
            results.AddRange(response);
        }
        return results;
    }

    public async Task SaveAsync(Entity entity)
    {
        await _cosmosRepository.UpsertDocumentAsync(entity);
    }

    public async Task DeleteAsync(Guid organizationId, Guid entityId)
    {
        var partition = BuildPartition(organizationId);
        await _cosmosRepository.DeleteDocumentAsync<Entity>(
            partition, 
            entityId.ToString());
    }

    public async Task<bool> ExistsAsync(Guid organizationId, Guid entityId)
    {
        var partition = BuildPartition(organizationId);
        return await _cosmosRepository.ExistsAsync<Entity>(
            partition, 
            entityId.ToString());
    }

    private static string BuildPartition(Guid organizationId) =>
        $"Entity/{organizationId}";
}
```

### Document Model
```csharp
public class Entity : BaseCosmosDocument
{
    public Guid EntityId { get; set; }
    public Guid OrganizationId { get; set; }
    public Guid PatientId { get; set; }
    public string Name { get; set; } = string.Empty;
    public EntityStatus Status { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public override string Partition => $"Entity/{OrganizationId}";
    public override string Identity => EntityId.ToString();
}
```

## Blob Storage Repository

### Interface
```csharp
public interface IEntityBlobRepository
{
    Task<Entity?> GetAsync(Guid organizationId, Guid entityId);
    Task SaveAsync(Entity entity);
    Task DeleteAsync(Guid organizationId, Guid entityId);
    Task<bool> ExistsAsync(Guid organizationId, Guid entityId);
    Task UpdateAsync(Guid organizationId, Guid entityId, Func<Entity, Entity> mutator);
}
```

### Implementation
```csharp
public class EntityBlobRepository : IEntityBlobRepository
{
    private readonly IBlobRepository _blobRepository;

    public EntityBlobRepository(IBlobRepository blobRepository)
    {
        _blobRepository = blobRepository;
    }

    public async Task<Entity?> GetAsync(Guid organizationId, Guid entityId)
    {
        return await _blobRepository.ReadDocumentByIdAsync<Entity>(
            organizationId.ToString(),
            entityId.ToString());
    }

    public async Task SaveAsync(Entity entity)
    {
        await _blobRepository.WriteDocumentAsync(entity);
    }

    public async Task DeleteAsync(Guid organizationId, Guid entityId)
    {
        await _blobRepository.DeleteDocumentAsync<Entity>(
            organizationId.ToString(),
            entityId.ToString());
    }

    public async Task<bool> ExistsAsync(Guid organizationId, Guid entityId)
    {
        return await _blobRepository.ExistsAsync<Entity>(
            organizationId.ToString(),
            entityId.ToString());
    }

    public async Task UpdateAsync(
        Guid organizationId, 
        Guid entityId, 
        Func<Entity, Entity> mutator)
    {
        var existing = await GetAsync(organizationId, entityId);
        if (existing == null)
        {
            // Create new with default values
            existing = new Entity
            {
                OrganizationId = organizationId,
                EntityId = entityId
            };
        }
        
        var updated = mutator(existing);
        await _blobRepository.ConcurrentDocumentUpdateAsync(existing, _ => updated);
    }
}
```

### Blob Document Model
```csharp
public class Entity : IBaseDocument
{
    public Guid OrganizationId { get; set; }
    public Guid EntityId { get; set; }
    public string Name { get; set; } = string.Empty;
    
    // IBaseDocument implementation
    public string PartitionKey => OrganizationId.ToString();
    public string Id => EntityId.ToString();
}
```

## Concurrent Updates

### Cosmos DB
```csharp
public async Task UpdateAsync(Guid orgId, Guid entityId, Func<Entity, Entity> mutator)
{
    await _cosmosRepository.ConcurrentDocumentUpdateAsync<Entity>(
        BuildPartition(orgId),
        entityId.ToString(),
        mutator,
        retryLimit: 5);
}
```

### Blob Storage
```csharp
public async Task UpdateAsync(Guid orgId, Guid entityId, Func<Entity, Entity> mutator)
{
    var current = await GetAsync(orgId, entityId);
    if (current == null)
        throw new EntityNotFoundException(entityId);
    
    await _blobRepository.ConcurrentDocumentUpdateAsync(current, mutator);
}
```

## Search/Query Patterns

### Parameterized Queries
```csharp
public async Task<IEnumerable<Entity>> SearchAsync(
    Guid organizationId,
    SearchRequest request)
{
    var partition = BuildPartition(organizationId);
    
    Expression<Func<Entity, bool>> filter = e => true;
    
    if (!string.IsNullOrEmpty(request.Name))
        filter = filter.And(e => e.Name.Contains(request.Name));
    
    if (request.Status.HasValue)
        filter = filter.And(e => e.Status == request.Status.Value);
    
    var iterator = await _cosmosRepository.QueryDocumentsAsync(
        partition,
        filter,
        maxItems: request.PageSize,
        skip: request.PageNumber * request.PageSize);
    
    return await iterator.ToListAsync();
}
```

## Dependency Injection

```csharp
// In Program.cs or ConfigureServices
services.AddSingleton<ICosmosRepository>(
    CosmosRepositoryFactory.Create(config));
services.AddSingleton<IBlobRepository, BlobRepository>();

services.AddSingleton<IEntityRepository, EntityRepository>();
services.AddSingleton<IEntityBlobRepository, EntityBlobRepository>();
```

## Best Practices

1. **Use partition keys wisely** - Design for access patterns
2. **Implement optimistic concurrency** - Use ETags
3. **Handle not found gracefully** - Return null, not exception
4. **Use expressions for queries** - Type-safe and optimizable
5. **Consider read/write costs** - Point reads are cheaper
6. **Separate concerns** - One repository per aggregate
