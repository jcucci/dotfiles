---
description: Find a .NET type using Sherlock MCP
model: anthropic/claude-haiku-4-5-20251001
---

Find information about a .NET type: $ARGUMENTS

Use the dotnet-sherlock MCP tools to find and analyze the requested type.

## Your Task

1. **Search for the type** using the class name provided in $ARGUMENTS

2. **If found**, show:
   - Full type name and namespace
   - Assembly location
   - Base class and interfaces
   - Key public members (methods, properties)

3. **If not found**, suggest:
   - Check spelling
   - Try partial name matches
   - Build the solution first if assemblies are missing

Use the Sherlock MCP tools:
- `find_assembly_by_class_name` to locate the assembly
- `get_type_info` for type details
- `get_type_methods` or `get_type_properties` for members

Keep the output focused on what's useful for understanding and using the type.
