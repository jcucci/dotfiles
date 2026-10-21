---
name: cosmos-query-patterns
description: Cosmos DB query optimization, partition strategies, and common patterns
---

# Cosmos DB Query Patterns

Reference for efficient Cosmos DB operations.

## Partition Key Design

### Good Partition Keys
- High cardinality (many distinct values)
- Even distribution
- Frequently used in queries
- Natural grouping

### Common Patterns
```
Per-organization:     /{organizationId}
Per-patient:          /{organizationId}_{patientId}
Per-entity-type:      /EntityType/{organizationId}
Composite:            /{organizationId}/{entityType}
```

### Document Model
```csharp
public class Entity : BaseCosmosDocument
{
    public Guid OrganizationId { get; set; }
    public Guid EntityId { get; set; }
    
    // Partition key property
    public override string Partition => $"Entity/{OrganizationId}";
    
    // Identity within partition
    public override string Identity => EntityId.ToString();
}
```

## Query Patterns

### Point Read (Most Efficient)
```csharp
// Direct lookup by partition key + id
var entity = await cosmosRepository.ReadDocumentByIdAsync<Entity>(
    partitionKey: $"Entity/{organizationId}",
    id: entityId.ToString());
```

### Query Within Partition
```csharp
// Efficient - scoped to single partition
var iterator = await cosmosRepository.QueryDocumentsAsync<Entity>(
    partitionKey: $"Entity/{organizationId}",
    expression: e => e.Status == EntityStatus.Active);
```

### Cross-Partition Query (Avoid if possible)
```csharp
// Expensive - fans out to all partitions
var iterator = await cosmosRepository.QueryDocumentsAsync<Entity>(
    partitionKey: null, // Cross-partition
    expression: e => e.Name.Contains(searchTerm));
```

## Expression-Based Queries

### Simple Filter
```csharp
await cosmosRepository.QueryDocumentsAsync<Entity>(
    partition,
    e => e.Status == EntityStatus.Active);
```

### Multiple Conditions
```csharp
await cosmosRepository.QueryDocumentsAsync<Entity>(
    partition,
    e => e.Status == EntityStatus.Active 
      && e.CreatedAt > startDate
      && e.CreatedAt < endDate);
```

### String Contains
```csharp
await cosmosRepository.QueryDocumentsAsync<Entity>(
    partition,
    e => e.Name.Contains(searchTerm));
```

### Collection Contains
```csharp
var statusList = new[] { EntityStatus.Active, EntityStatus.Pending };

await cosmosRepository.QueryDocumentsAsync<Entity>(
    partition,
    e => statusList.Contains(e.Status));
```

## Pagination

### Skip/Take Pattern
```csharp
var iterator = await cosmosRepository.QueryDocumentsAsync<Entity>(
    partition,
    expression: e => true,
    maxItems: pageSize,
    skip: pageNumber * pageSize);
```

### Continuation Token (Preferred for Large Sets)
```csharp
var result = await cosmosRepository.QueryWithContinuationAsync<Entity>(
    partition,
    expression,
    continuationToken: request.ContinuationToken,
    maxItems: request.PageSize);

return new PagedResult<Entity>
{
    Items = result.Items,
    ContinuationToken = result.ContinuationToken,
    HasMore = result.ContinuationToken != null
};
```

## Concurrent Updates

### Optimistic Concurrency
```csharp
await cosmosRepository.ConcurrentDocumentUpdateAsync<Entity>(
    partition,
    entityId.ToString(),
    entity =>
    {
        return entity with { 
            Status = EntityStatus.Complete,
            UpdatedAt = DateTime.UtcNow 
        };
    },
    retryLimit: 5);
```

### Create or Update
```csharp
await cosmosRepository.ConcurrentDocumentUpdateAsync<Entity>(
    partition,
    entityId.ToString(),
    existing =>
    {
        if (existing == null)
        {
            return new Entity
            {
                EntityId = entityId,
                OrganizationId = organizationId,
                CreatedAt = DateTime.UtcNow
            };
        }
        
        return existing with { UpdatedAt = DateTime.UtcNow };
    });
```

## Counting

```csharp
var count = await cosmosRepository.CountAsync<Entity>(
    partition,
    e => e.Status == EntityStatus.Active);
```

## Batch Operations

### Bulk Read
```csharp
var entities = new List<Entity>();
var iterator = await cosmosRepository.QueryDocumentsAsync<Entity>(
    partition,
    e => entityIds.Contains(e.EntityId),
    maxItems: 100);

while (iterator.HasMoreResults)
{
    var response = await iterator.ReadNextAsync();
    entities.AddRange(response);
}
```

### Bulk Write (Transactional Batch)
```csharp
// Within same partition only
await cosmosRepository.BatchAsync(partition, batch =>
{
    foreach (var entity in entities)
    {
        batch.UpsertItem(entity);
    }
});
```

## Performance Tips

1. **Use point reads** when you have partition key + id
2. **Stay within partition** - cross-partition is expensive
3. **Limit result sets** - use maxItems
4. **Index appropriately** - review indexing policy
5. **Use projections** - select only needed fields
6. **Cache reference data** - reduce RU consumption
7. **Monitor RU usage** - set alerts on consumption

## RU Optimization

| Operation | Approximate RU |
|-----------|---------------|
| Point read | ~1 RU |
| Query (indexed) | 3-10 RU |
| Query (scan) | 10-100+ RU |
| Write (1KB) | ~5 RU |
| Cross-partition | Multiplied by partition count |

## Common Anti-Patterns

1. **Low cardinality partition keys** - hot partitions
2. **Large documents** - split into smaller
3. **Unbounded queries** - always limit
4. **Missing indexes** - check query plans
5. **Sync over async** - always use async
