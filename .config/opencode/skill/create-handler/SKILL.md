---
name: create-handler
description: Guide for implementing IEventHandler with RelevantEventCollection and batch processing patterns
---

# Creating an Event Handler

This skill guides you through creating an event handler that processes batched events from a change feed.

## Handler Structure

```csharp
internal class Handler : IEventHandler
{
    // 1. Define relevant events
    private static readonly RelevantEventCollection RelevantEvents = ...;
    
    // 2. Dependencies
    private readonly IRepository _repository;
    
    // 3. Static filter method for projector
    public static bool CanProcessRecord(RecordedEventType eventType) => ...;
    
    // 4. Main processing method
    public async Task HandleAsync(EventBatchChangeSet batch) { ... }
}
```

## Step 1: Define Relevant Events

Register all event types this handler will process:

```csharp
private static readonly RelevantEventCollection RelevantEvents = 
    RelevantEventCollectionBuilder.Create()
        .Register<EntityCreated>()
        .Register<EntityUpdated>()
        .Register<EntityDeleted>()
        .Register<PropertyChanged>()
        .Build();
```

**Important**: Events not registered here will be silently skipped.

## Step 2: Filter Method

Used by the Projector to filter at the record level:

```csharp
public static bool CanProcessRecord(RecordedEventType eventType) =>
    RelevantEvents.CanProcess(eventType);
```

## Step 3: Batch Processing

Always process events in batches, grouped by entity:

```csharp
public async Task HandleAsync(EventBatchChangeSet batch)
{
    // Deserialize all events in batch
    var events = EventDeserializer.DeserializeEntityEvents(batch, RelevantEvents);
    
    // Group by entity identifier
    var groupedEvents = events.GroupBy(e => e.Identifier);
    
    // Process in parallel with concurrency limit
    await groupedEvents.ForEachAsync(20, async group =>
    {
        await ProcessEntityEventsAsync(group.Key, group);
    });
}
```

## Step 4: Entity Processing

Process all events for a single entity:

```csharp
private async Task ProcessEntityEventsAsync(
    EventStreamIdentifier identifier,
    IEnumerable<DeserializedEvent> events)
{
    // Use repository's update pattern for atomic updates
    await _repository.UpdateAsync(
        identifier.TenantId,
        identifier.EntityId,
        projection => ApplyEvents(projection, events));
}

private static Projection ApplyEvents(
    Projection projection, 
    IEnumerable<DeserializedEvent> events)
{
    foreach (var e in events)
    {
        projection = e.Event switch
        {
            EntityCreated created => HandleCreated(projection, created),
            EntityUpdated updated => HandleUpdated(projection, updated),
            EntityDeleted deleted => HandleDeleted(projection, deleted),
            _ => projection // Unknown events are ignored
        };
    }
    return projection;
}
```

## Change Tracking Pattern

When you need to trigger downstream projections:

```csharp
public async Task HandleAsync(EventBatchChangeSet batch)
{
    // Track what entities were changed
    var changeTracker = new ChangeTracker();
    
    await EventDeserializer.DeserializeEntityEvents(batch, RelevantEvents)
        .GroupBy(e => e.Identifier)
        .ForEachAsync(20, async group =>
        {
            await ProcessEntityEventsAsync(group.Key, group, changeTracker);
        });
    
    // Enqueue downstream work
    await EnqueueDownstreamUpdatesAsync(changeTracker);
}

private async Task EnqueueDownstreamUpdatesAsync(ChangeTracker tracker)
{
    // Workspace builds
    await _workspaceWriter.EnqueueAsync(
        tracker.Changes.Select(c => new WorkspaceBuildRequest(c.Id)));
    
    // Search index updates
    await _searchWriter.EnqueueAsync(
        tracker.Changes.Select(c => new SearchUpdateRequest(c.Id)));
}
```

## Complete Example

```csharp
internal class PatientChargeHandler : IEventHandler
{
    private static readonly RelevantEventCollection RelevantEvents = 
        RelevantEventCollectionBuilder.Create()
            .Register<ChargeCreated>()
            .Register<ChargeUpdated>()
            .Register<ChargeStatusChanged>()
            .Register<ChargeDeleted>()
            .Build();

    private readonly PatientChargeRepository _repository;
    private readonly IWorkspaceBuildRequestWriter _workspaceWriter;
    private readonly ILogger<PatientChargeHandler> _logger;

    public PatientChargeHandler(
        PatientChargeRepository repository,
        IWorkspaceBuildRequestWriter workspaceWriter,
        ILogger<PatientChargeHandler> logger)
    {
        _repository = repository;
        _workspaceWriter = workspaceWriter;
        _logger = logger;
    }

    public static bool CanProcessRecord(RecordedEventType eventType) =>
        RelevantEvents.CanProcess(eventType);

    public async Task HandleAsync(EventBatchChangeSet batch)
    {
        var changeTracker = new ChargeAssemblyChangeTracker();

        await EventDeserializer.DeserializeEntityEvents(batch, RelevantEvents)
            .GroupBy(e => e.Identifier)
            .ForEachAsync(20, async group =>
            {
                using var scope = _logger.BeginScope(
                    new { TenantId = group.Key.TenantId, ChargeId = group.Key.EntityId });
                
                try
                {
                    await ProcessChargeEventsAsync(group.Key, group, changeTracker);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to process charge events");
                    throw;
                }
            });

        await _workspaceWriter.EnqueueAsync(
            changeTracker.GetWorkspaceRequests());
    }

    private async Task ProcessChargeEventsAsync(
        EventStreamIdentifier identifier,
        IEnumerable<DeserializedEvent> events,
        ChargeAssemblyChangeTracker tracker)
    {
        await _repository.UpdateAsync(
            identifier.TenantId,
            identifier.EntityId,
            projection =>
            {
                foreach (var e in events)
                {
                    projection = ApplyEvent(projection, e, tracker);
                }
                return projection;
            });
    }

    private PatientChargeProjection ApplyEvent(
        PatientChargeProjection projection,
        DeserializedEvent e,
        ChargeAssemblyChangeTracker tracker)
    {
        switch (e.Event)
        {
            case ChargeCreated created:
                tracker.TrackChange(created.ChargeAssemblyId);
                return projection.AddCharge(created);
                
            case ChargeUpdated updated:
                tracker.TrackChange(updated.ChargeAssemblyId);
                return projection.UpdateCharge(updated);
                
            case ChargeDeleted deleted:
                tracker.TrackChange(deleted.ChargeAssemblyId);
                return projection.RemoveCharge(deleted.ChargeId);
                
            default:
                return projection;
        }
    }
}
```

## Best Practices

1. **Never process events one at a time** - Always batch
2. **Use ForEachAsync with concurrency limit** - 10-20 is typical
3. **Log with context** - Use scoped logging for debugging
4. **Handle errors gracefully** - Log and rethrow for retry
5. **Track changes for downstream** - Use change trackers
6. **Keep handlers focused** - One handler per domain concern
