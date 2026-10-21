---
name: create-unit-tests
description: Guide for xUnit tests with fixtures, assertions, and in-memory implementations
---

# Creating Unit Tests

This skill covers unit testing patterns with xUnit, fixtures, and in-memory implementations.

## Test Structure

```csharp
[Trait("Category", "DomainName")]
public class EntityHandlerTests
{
    // In-memory implementations
    private readonly IBlobRepository _blobRepository = new InMemoryBlobRepository();
    private readonly ICosmosRepository _cosmosRepository = new InMemoryCosmosRepository();
    private readonly InMemoryEventPublisher _eventPublisher = new InMemoryEventPublisher();
    
    // Mocks for external dependencies
    private readonly IServiceBusQueue _serviceBusQueue = Substitute.For<IServiceBusQueue>();

    [Fact]
    public async Task MethodName_Scenario_ExpectedResult()
    {
        // Arrange
        await SetupTestData();
        var input = CreateInput();

        // Act
        var result = await CreateHandler().HandleAsync(input);

        // Assert
        await VerifyResult();
    }

    private Handler CreateHandler() =>
        new Handler(
            repository: new EntityRepository(_blobRepository),
            eventWriter: CreateEventWriter());
}
```

## Naming Convention

`MethodName_Scenario_ExpectedResult`

Examples:
- `HandleAsync_EntityCreated_ProjectionUpdated`
- `GetAsync_NotFound_ReturnsNull`
- `CreateAsync_DuplicateId_ThrowsException`
- `ProcessEvents_Idempotency_NoDoubleProcessing`

## Fixture Classes

### Purpose
- Centralize test data
- Ensure consistency across tests
- Provide setup methods

### Example Fixture
```csharp
internal static class EntityFixture
{
    // Static IDs for consistency
    public static readonly Guid EntityId1 = Guid.NewGuid();
    public static readonly Guid EntityId2 = Guid.NewGuid();
    public static readonly Guid OrganizationId = Guid.NewGuid();
    public static readonly Guid PatientId = Guid.NewGuid();

    // Default objects
    public static Entity DefaultEntity => new Entity
    {
        EntityId = EntityId1,
        OrganizationId = OrganizationId,
        PatientId = PatientId,
        Name = "Test Entity",
        Status = EntityStatus.Active
    };

    // Setup methods
    public static async Task SetupAsync(IBlobRepository repository)
    {
        await repository.WriteDocumentAsync(DefaultEntity);
    }

    // Event stream identifiers
    public static EventStreamIdentifier Identifier1 =>
        EventStreamIdentifier.Create(
            new SourceApplication("test-app"),
            OrganizationId,
            "entity",
            EntityId1);
}
```

## Assertion Classes

### Purpose
- Encapsulate verification logic
- Read from repositories to verify state
- Provide meaningful failure messages

### Example Assertion
```csharp
internal static class EntityAssert
{
    public static async Task EntityExistsAsync(
        IBlobRepository repository,
        Guid entityId)
    {
        var entity = await repository.ReadDocumentByIdAsync<Entity>(
            EntityFixture.OrganizationId.ToString(),
            entityId.ToString());

        Assert.NotNull(entity);
        Assert.Equal(entityId, entity.EntityId);
    }

    public static async Task EntityHasStatusAsync(
        IBlobRepository repository,
        Guid entityId,
        EntityStatus expectedStatus)
    {
        var entity = await repository.ReadDocumentByIdAsync<Entity>(
            EntityFixture.OrganizationId.ToString(),
            entityId.ToString());

        Assert.NotNull(entity);
        Assert.Equal(expectedStatus, entity.Status);
    }

    public static void EventPublished<TEvent>(
        InMemoryEventPublisher publisher,
        EventStreamIdentifier identifier)
        where TEvent : class
    {
        publisher.AssertEvent<TEvent>(identifier, _ => true);
    }
}
```

## In-Memory Implementations

### InMemoryBlobRepository
```csharp
private readonly IBlobRepository _blobRepository = new InMemoryBlobRepository();

// Write
await _blobRepository.WriteDocumentAsync(entity);

// Read
var entity = await _blobRepository.ReadDocumentByIdAsync<Entity>(
    partitionKey, id);

// Concurrent update
await _blobRepository.ConcurrentDocumentUpdateAsync(
    entity, 
    e => e with { Status = EntityStatus.Complete });
```

### InMemoryEventPublisher
```csharp
private readonly InMemoryEventPublisher _eventPublisher = new InMemoryEventPublisher();

// Publish events
await _eventPublisher.PublishEventAsync(identifier, @event);

// Assert event was published
_eventPublisher.AssertEvent<EntityCreated>(
    identifier, 
    e => e.EntityId == expectedId);

// Assert no events
_eventPublisher.AssertNoEvents<EntityCreated>(identifier);
```

## Testing Patterns

### Handler Testing
```csharp
[Fact]
public async Task HandleAsync_EntityCreatedEvent_UpdatesProjection()
{
    // Arrange
    await EntityFixture.SetupOpenEventsAsync(_eventPublisher);
    
    var @event = new EntityCreated(
        EntityId: EntityFixture.EntityId1,
        Name: "Test");
    
    var batch = RecordedEventFixture.WrapEvent(@event, EntityFixture.Identifier1);

    // Act
    await CreateHandler().HandleAsync(RecordedEventFixture.BatchFor(batch));

    // Assert
    await EntityAssert.EntityExistsAsync(_blobRepository, EntityFixture.EntityId1);
    EntityAssert.EventPublished<ProjectionUpdated>(_eventPublisher, EntityFixture.Identifier1);
}
```

### Controller Testing
```csharp
[Fact]
public async Task GetAsync_NotFound_Returns404()
{
    // Arrange - no setup, entity doesn't exist

    // Act
    var result = await CreateController().GetAsync(
        EntityFixture.PatientId,
        EntityFixture.EntityId1);

    // Assert
    Assert.IsType<NotFoundResult>(result.Result);
}

[Fact]
public async Task GetAsync_Exists_ReturnsEntity()
{
    // Arrange
    await EntityFixture.SetupAsync(_blobRepository);

    // Act
    var result = await CreateController().GetAsync(
        EntityFixture.PatientId,
        EntityFixture.EntityId1);

    // Assert
    Assert.NotNull(result.Value);
    Assert.Equal(EntityFixture.EntityId1, result.Value.Id);
}
```

### Idempotency Testing
```csharp
[Fact]
public async Task HandleAsync_SameEventTwice_IdempotentResult()
{
    // Arrange - Setup with existing data
    await EntityFixture.SetupAsync(_blobRepository);
    var @event = new EntityUpdated(EntityId: EntityFixture.EntityId1);
    var batch = RecordedEventFixture.WrapEvent(@event, EntityFixture.Identifier1);

    // Act - Process same event twice
    await CreateHandler().HandleAsync(batch);
    await CreateHandler().HandleAsync(batch);

    // Assert - Should have same result, not duplicate
    await EntityAssert.SingleEntityAsync(_blobRepository, EntityFixture.EntityId1);
}
```

## Mocking External Dependencies

```csharp
private readonly IServiceBusQueue _queue = Substitute.For<IServiceBusQueue>();

[Fact]
public async Task HandleAsync_EnqueuesWorkspaceRequest()
{
    // Arrange
    await EntityFixture.SetupAsync(_blobRepository);

    // Act
    await CreateHandler().HandleAsync(batch);

    // Assert
    await _queue.Received(1).EnqueueAsync(
        QueueConstants.WorkspaceQueueName,
        Arg.Is<WorkspaceRequest[]>(r => 
            r.Any(x => x.EntityId == EntityFixture.EntityId1)));
}
```

## Best Practices

1. **Use in-memory implementations** - Not mocks for repositories
2. **Mock only external I/O** - Queues, HTTP clients, loggers
3. **Use fixtures for test data** - Consistent and reusable
4. **Use assertions for verification** - Encapsulate complex checks
5. **Test idempotency** - Event handlers must be replayable
6. **Name tests descriptively** - Method_Scenario_Expected
7. **One assertion per test** - Or closely related assertions
