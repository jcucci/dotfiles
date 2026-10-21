---
name: dotnet-async-patterns
description: .NET async/await best practices, ConfigureAwait, and common patterns
---

# .NET Async Patterns

Best practices for async/await in .NET.

## Basic Patterns

### Async Method Structure
```csharp
public async Task<Result> ProcessAsync(Request request)
{
    // Async operations with await
    var data = await _repository.GetAsync(request.Id);
    var processed = await _processor.ProcessAsync(data);
    return processed;
}
```

### Naming Convention
- Suffix with `Async`: `GetAsync`, `SaveAsync`, `ProcessAsync`
- Exception: Event handlers can be `async void`

## ConfigureAwait

### Library Code
```csharp
// In library/infrastructure code - avoid capturing context
public async Task<T> GetAsync<T>(string id)
{
    var result = await _client.ReadAsync(id).ConfigureAwait(false);
    return result;
}
```

### Application Code
```csharp
// In controllers/handlers - usually omit ConfigureAwait
public async Task<IActionResult> GetAsync(Guid id)
{
    var result = await _service.GetAsync(id);
    return Ok(result);
}
```

## Avoid Blocking

### Bad - Deadlock Risk
```csharp
// NEVER do this
var result = _repository.GetAsync(id).Result;
var result = _repository.GetAsync(id).GetAwaiter().GetResult();
_repository.SaveAsync(entity).Wait();
```

### Good - Async All The Way
```csharp
var result = await _repository.GetAsync(id);
await _repository.SaveAsync(entity);
```

## Parallel Operations

### When Tasks Are Independent
```csharp
// Start all tasks
var task1 = _repo1.GetAsync(id1);
var task2 = _repo2.GetAsync(id2);
var task3 = _repo3.GetAsync(id3);

// Await all together
await Task.WhenAll(task1, task2, task3);

// Access results
var result1 = task1.Result; // Safe - task completed
var result2 = task2.Result;
var result3 = task3.Result;
```

### With Results
```csharp
var results = await Task.WhenAll(
    _repo1.GetAsync(id1),
    _repo2.GetAsync(id2),
    _repo3.GetAsync(id3));

// results[0], results[1], results[2]
```

### Controlled Parallelism
```csharp
// Process items with max concurrency
await items.ForEachAsync(maxConcurrency: 20, async item =>
{
    await ProcessAsync(item);
});
```

## Cancellation

### Accepting CancellationToken
```csharp
public async Task<Result> ProcessAsync(
    Request request, 
    CancellationToken cancellationToken = default)
{
    cancellationToken.ThrowIfCancellationRequested();
    
    var data = await _repository.GetAsync(
        request.Id, 
        cancellationToken);
    
    return await _processor.ProcessAsync(
        data, 
        cancellationToken);
}
```

### Propagating Cancellation
```csharp
public async Task<IActionResult> GetAsync(
    Guid id, 
    CancellationToken cancellationToken)
{
    var result = await _service.GetAsync(id, cancellationToken);
    return Ok(result);
}
```

### Timeouts
```csharp
using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(30));
try
{
    await _service.ProcessAsync(request, cts.Token);
}
catch (OperationCanceledException) when (cts.IsCancellationRequested)
{
    // Timeout occurred
    throw new TimeoutException("Operation timed out");
}
```

## Exception Handling

### Try-Catch with Async
```csharp
try
{
    await _service.ProcessAsync(request);
}
catch (EntityNotFoundException ex)
{
    _logger.LogWarning(ex, "Entity not found: {Id}", request.Id);
    return NotFound();
}
catch (Exception ex)
{
    _logger.LogError(ex, "Unexpected error processing {Id}", request.Id);
    throw;
}
```

### WhenAll Exception Handling
```csharp
try
{
    await Task.WhenAll(task1, task2, task3);
}
catch (Exception)
{
    // Only first exception is thrown
    // Check individual tasks for all exceptions
    if (task1.IsFaulted)
        _logger.LogError(task1.Exception, "Task 1 failed");
    if (task2.IsFaulted)
        _logger.LogError(task2.Exception, "Task 2 failed");
    throw;
}
```

## ValueTask

### When to Use
```csharp
// Use ValueTask when result is often synchronous (cached)
public ValueTask<Entity> GetAsync(Guid id)
{
    if (_cache.TryGetValue(id, out var cached))
        return ValueTask.FromResult(cached); // No allocation
    
    return new ValueTask<Entity>(LoadFromDatabaseAsync(id));
}
```

### Rules
- Only await once
- Don't cache ValueTask
- Convert to Task if needed: `.AsTask()`

## Async Void

### Only for Event Handlers
```csharp
// OK - event handler
private async void Button_Click(object sender, EventArgs e)
{
    await ProcessAsync();
}

// BAD - regular method
private async void ProcessData() // Exceptions will crash!
{
    await _repository.SaveAsync(data);
}
```

## Lazy Initialization

```csharp
private readonly AsyncLazy<ExpensiveResource> _resource;

public MyService()
{
    _resource = new AsyncLazy<ExpensiveResource>(
        async () => await InitializeResourceAsync());
}

public async Task UseResourceAsync()
{
    var resource = await _resource.Value;
    // Use resource
}
```

## Common Anti-Patterns

### 1. Async Over Sync
```csharp
// BAD - Wrapping sync in Task.Run
public Task<int> GetCountAsync()
{
    return Task.Run(() => _list.Count); // Unnecessary
}

// GOOD - Just return synchronously
public int GetCount() => _list.Count;
```

### 2. Sync Over Async
```csharp
// BAD - Blocking on async
public int GetValue()
{
    return GetValueAsync().Result; // Deadlock risk!
}

// GOOD - Stay async
public async Task<int> GetValueAsync()
{
    return await _service.GetValueAsync();
}
```

### 3. Fire and Forget Without Handling
```csharp
// BAD - Exception is lost
_ = ProcessAsync(); // Don't do this

// OK - If you really need fire-and-forget
_ = Task.Run(async () =>
{
    try
    {
        await ProcessAsync();
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Background task failed");
    }
});
```

## Best Practices Summary

1. **Async all the way** - Don't mix sync and async
2. **Use ConfigureAwait(false)** in library code
3. **Always propagate CancellationToken**
4. **Prefer Task over ValueTask** unless hot path
5. **Never use async void** except event handlers
6. **Use Task.WhenAll** for parallel operations
7. **Handle exceptions** at appropriate levels
8. **Name methods with Async suffix**
