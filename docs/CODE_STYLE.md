# Dart Agent Code Style Manual

A comprehensive guide for writing clean, maintainable, and idiomatic Dart code
when building AI agents.

---

## Table of Contents

1. [Naming Conventions](#1-naming-conventions)
2. [File & Project Structure](#2-file--project-structure)
3. [Formatting & Style](#3-formatting--style)
4. [Tool Definitions](#4-tool-definitions)
5. [Agent Class Structure](#5-agent-class-structure)
6. [The Agent Loop](#6-the-agent-loop)
7. [Error Handling](#7-error-handling)
8. [State & Memory](#8-state--memory)
9. [Async Patterns](#9-async-patterns)
10. [Prompts](#10-prompts)
11. [Testing](#11-testing)
12. [Documentation](#12-documentation)
13. [BLoC Rules](#13-bloc-rules)
14. [Linter Rules Reference](#14-linter-rules-reference)

---

## 1. Naming Conventions

> **Enforced by:** `camel_case_types`, `non_constant_identifier_names`,
`library_names`, `library_prefixes`, `package_names`,
`package_prefixed_library_names`

### Classes

Use `PascalCase` (`camel_case_types`). Agent classes must have an `Agent`
suffix. Tool classes use a `Tool` suffix.

```dart
// ✅ Good
class ResearchAgent extends BaseAgent {}

class WebSearchTool implements AgentTool {}

class ShortTermMemory {}

// ❌ Bad
class research_agent {}

class Searcher {}

class STM {}
```

### Functions & Methods

Use `camelCase` (`non_constant_identifier_names`). Tool execution methods use a
verb prefix. Always declare return types explicitly (
`always_declare_return_types`). Never rename parameters when overriding a
method — keep the same parameter names as the parent (
`avoid_renaming_method_parameters`).

```dart
// ✅ Good
Future<String> searchWeb(String query) async {}

Future<String> readFile(String path) async {}

String formatToolResult(String toolUseId, String content) {}

// ❌ Bad
Future<String> web(String q) async {}

Future<String> FileRead(String path) async {}

web(q) async {} // missing return type
```

### Variables

Use `camelCase` (`non_constant_identifier_names`). Be explicit with
agent-specific concepts — avoid abbreviations.

```dart
// ✅ Good
final List<Message> trajectory = [];
final String systemPrompt;
final int maxSteps;
String observation = '';

// ❌ Bad
final List<Message> traj = [];
final String sp;
final int ms;
String obs = '';
```

### Constants

Use `camelCase` for `const` values in Dart (per Dart style guide). Use
`SCREAMING_SNAKE_CASE` only for environment/config keys.

```dart
// ✅ Good
const int defaultMaxSteps = 20;
const String defaultModel = 'claude-opus-4-6';
const String apiKeyEnvVar = 'ANTHROPIC_API_KEY';

// ❌ Bad
const int DEFAULT_MAX_STEPS = 20;
const String DefaultModel = 'claude-opus-4-6';
```

### Files

Use `snake_case` for all filenames. Library names follow
`package_prefixed_library_names` — prefix with the package name to avoid
collisions.

```
base_agent.dart
web_search_tool.dart
short_term_memory.dart
agent_exception.dart
```

```dart
// ✅ Good
library my_app.agents.research_agent;

// ❌ Bad
library ResearchAgent;

library research

-
agent;
```

---

## 2. File & Project Structure

```
lib/
  agents/
    base_agent.dart          # Abstract base class
    planner_agent.dart       # Concrete agent implementations
    researcher_agent.dart

  tools/
    agent_tool.dart          # AgentTool interface
    web_search_tool.dart     # One tool per file
    file_reader_tool.dart
    tool_registry.dart       # Central tool dispatcher

  memory/
    short_term_memory.dart
    long_term_memory.dart
    memory_retriever.dart

  models/
    message.dart             # Message, ToolUse, ToolResult types
    agent_response.dart
    tool_schema.dart

  prompts/
    prompt_loader.dart       # Loads prompts from assets
  
  exceptions/
    agent_exception.dart
    tool_exception.dart

assets/
  prompts/
    system_prompt.txt        # Prompts as asset files, not hardcoded strings
    planner_prompt.txt
    researcher_prompt.txt

test/
  agents/
    base_agent_test.dart
  tools/
    web_search_tool_test.dart
  memory/
    short_term_memory_test.dart
```

---

## 3. Formatting & Style

Always run `dart format` before committing. The project should enforce this in
CI.

### Line Length

Keep lines under **80 characters** (Dart's default). For long strings or
parameters, break with trailing commas.

```dart
// ✅ Good
final AgentResponse response = await
client.messages.create
(
model: defaultModel,
maxTokens: 1024,
system: systemPrompt,
messages: trajectory,
);

// ❌ Bad
final AgentResponse response = await client.messages.create(model: defaultModel, maxTokens: 1024, system: systemPrompt, messages
:
trajectory
);
```

### Trailing Commas

Always use trailing commas in multi-line collections and parameter lists. This
produces cleaner diffs and better `dart format` output.

```dart
// ✅ Good
final List<AgentTool> tools = [
  webSearchTool,
  fileReaderTool,
  emailSenderTool,
];

// ❌ Bad
final List<AgentTool> tools = [webSearchTool, fileReaderTool, emailSenderTool];
```

### Control Flow

> **Enforced by:** `always_put_control_body_on_new_line`, `avoid_empty_else`,
`empty_statements`, `control_flow_in_finally`, `throw_in_finally`

Always put control flow bodies on a new line — even single-statement `if`
bodies (`always_put_control_body_on_new_line`). Never put logic inside a
`finally` block that throws or returns, as it swallows exceptions (
`control_flow_in_finally`, `throw_in_finally`).

```dart
// ✅ Good
if (response == null)
return;

if (isLoading) {
emit(AgentLoading());
} else {
emit(AgentReady());
}

// ❌ Bad — body on same line
if (response == null) return;

// ❌ Bad — empty else is unnecessary noise
if (isLoading) {
emit(AgentLoading());
} else {}

// ❌ Bad — throw in finally swallows the original exception
try {
final String result = await _service.run(input);
} finally {
throw AgentException('cleanup failed'); // hides original error
}
```

### Strings

> **Enforced by:** `prefer_single_quotes`,
`prefer_adjacent_string_concatenation`, `unnecessary_brace_in_string_interps`,
`no_adjacent_strings_in_list`

Use single quotes for all strings. Concatenate adjacent string literals directly
rather than using `+`. Only wrap interpolation expressions in `${}` when
necessary.

```dart
// ✅ Good
const String model = 'claude-opus-4-6';
final String message = 'Running step $currentStep of $maxSteps';
final String description =
    'Search the internet for current information. '
    'Use when you need facts that may have changed recently.';

// ❌ Bad
const String model = "claude-opus-4-6"; // double quotes
final String message = 'Step ' + '$currentStep'; // unnecessary concatenation
final String label = 'Tool: ${name}'; // unnecessary braces around simple identifier
final List<String> items = [
  'hello' 'world'
]; // adjacent strings in list — likely a bug
```

### Imports

> **Enforced by:** `directives_ordering`, `avoid_relative_lib_imports`,
`implementation_imports`

Order imports as: Dart SDK, then Flutter, then third-party packages, then local
files. Always use package imports (`package:`) for files inside `lib/` — never
relative paths. Do not import from another package's `src/` directory.

```dart
// ✅ Good
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:my_app/agents/base_agent.dart';
import 'package:my_app/tools/web_search_tool.dart';

// ❌ Bad
import '../../agents/base_agent.dart'; // relative lib import
import 'package:other_pkg/src/internal_thing.dart'; // implementation import
```

### Classes

> **Enforced by:** `avoid_classes_with_only_static_members`,
`sort_constructors_first`, `sort_unnamed_constructors_first`,
`prefer_initializing_formals`, `avoid_field_initializers_in_const_classes`,
`empty_constructor_bodies`, `overridden_fields`, `hash_and_equals`

Don't create classes that only contain static members — use top-level functions
instead. Constructors come first in a class body. Use initializing formals (
`this.field`) instead of manual assignment in constructor bodies. Whenever you
override `==`, also override `hashCode`.

```dart
// ✅ Good — use initializing formals
class AgentConfig {
  const AgentConfig({
    required this.model,
    required this.maxSteps,
  });

  final String model;
  final int maxSteps;
}

// ✅ Good — override both == and hashCode together
@override
bool operator
==
(
Object other) =>
other is AgentConfig && other.model == model && other.maxSteps == maxSteps;

@override
int get hashCode => Object.hash(model, maxSteps);

// ❌ Bad — class with only static members
class AgentUtils {
static String formatResult(String s) => s.trim();
static bool isValid(String s) => s.isNotEmpty;
}
// Prefer: top-level functions in a utils file

// ❌ Bad — empty constructor body
class AgentConfig {
AgentConfig(this.model, this.maxSteps) {} // use ; instead of {}
}

// ❌ Bad — overriding == without hashCode
@override
bool operator ==(Object other) => other is AgentConfig && other.model == model;
// hashCode not overridden — breaks Map/Set behaviour
```

### Collections

> **Enforced by:** `prefer_collection_literals`, `prefer_is_empty`,
`prefer_is_not_empty`, `prefer_contains`,
`avoid_function_literals_in_foreach_calls`, `prefer_foreach`,
`prefer_iterable_whereType`

Use collection literals instead of constructors. Prefer `.isEmpty` /
`.isNotEmpty` over length comparisons. Use `.contains()` instead of manual
iteration checks. Prefer `.whereType<T>()` for type filtering.

```dart
// ✅ Good
final List<AgentTool> tools = [];
final Map<String, String> headers = {};
final Set<String> seen = {};

if (
trajectory.isEmpty) return;
if (tools.isNotEmpty) registerTools();
final bool found = trajectory.contains(targetMessage);
final List<WebSearchTool> webTools = tools.whereType<WebSearchTool>().toList();

// ❌ Bad
final List<AgentTool> tools = List();
if (trajectory.length == 0) return;
if (tools.length > 0) registerTools();
final bool found = trajectory.any((Message m)
=>
m
==
targetMessage
);
```

### Parameter Assignments

> **Enforced by:** `parameter_assignments`

Never reassign a parameter inside a function body. If you need a modified
version, assign it to a new local variable. Reassigning parameters makes it easy
to lose track of the original value and signals unclear intent.

```dart
// ✅ Good — create a local variable for the modified value
Future<String> run(String input) async {
  final String sanitizedInput = input.trim();
  return _callModel(sanitizedInput);
}

// ❌ Bad — reassigning the parameter
Future<String> run(String input) async {
  input = input.trim(); // parameter reassigned
  return _callModel(input);
}
```

### Type Annotations

> **Enforced by:** `always_specify_types`,
`prefer_typing_uninitialized_variables`, `avoid_types_as_parameter_names`,
`avoid_return_types_on_setters`, `prefer_generic_function_type_aliases`

Always use explicit types everywhere — for local variables, fields, parameters,
and return types. Never use `var`. Use `dynamic` only when the type cannot be
known at compile time. Always type uninitialized variables. Use `typedef` with
generic function type alias syntax for function types.

```dart
// ✅ Good
class ResearchAgent extends BaseAgent {
  final List<Message> trajectory = [];
  final int maxSteps;

  Future<String> run(String userInput) async {}
}

// ✅ Good — typed typedef
typedef ToolExecutor = Future<String> Function(Map<String, dynamic> input);

// ❌ Bad
class ResearchAgent extends BaseAgent {
  var trajectory = [];
  var maxSteps;

  run(userInput) async {}
}

// ❌ Bad — type used as parameter name (shadows the type)
void register(Type String) {}
```

### Always Use Explicit Types — Never `var`

Always declare an explicit type. Never use `var`. Use `dynamic` only when the
type is genuinely undetermined at compile time (e.g., raw JSON values). When a
variable must be reassigned, declare it with its explicit type — not `var`.

```dart
// ✅ Good
final String model = 'claude-opus-4-6';
final List<AgentTool> tools;

// Reassignable — explicit type, not var
int currentStep = 0;
currentStep++;

// dynamic is acceptable only when type is truly unknown
final dynamic rawJson = jsonDecode(payload); // could be Map, List, String, etc.

// ❌ Bad — never use var
var model = 'claude-opus-4-6';
var tools = <AgentTool>[];
var currentStep = 0;

// ❌ Bad — don't use dynamic when the type is known
dynamic query = 'search term'; // should be String
dynamic maxSteps = 20; // should be int
```

### Const

> **Enforced by:** `prefer_const_constructors`,
`prefer_const_constructors_in_immutables`, `prefer_const_declarations`,
`prefer_const_literals_to_create_immutables`, `unnecessary_const`,
`unnecessary_new`

Use `const` constructors wherever possible — they are evaluated at compile time
and improve performance. Classes annotated with `@immutable` must declare all
their constructors as `const` (`prefer_const_constructors_in_immutables`). Never
use the `new` keyword. Don't add redundant `const` inside already-const
contexts.

```dart
// ✅ Good
const AgentConfig config = AgentConfig(model: 'claude-opus-4-6', maxSteps: 20);
final List<String> labels = const ['loading', 'ready', 'error'];

// ✅ Good — @immutable class uses const constructor
@immutable
class AgentConfig {
  const AgentConfig({required this.model, required this.maxSteps});

  final String model;
  final int maxSteps;
}

// ❌ Bad — @immutable class without const constructor
@immutable
class AgentConfig {
  AgentConfig({required this.model, required this.maxSteps}); // should be const
  final String model;
  final int maxSteps;
}

// ❌ Bad
final AgentConfig config = new AgentConfig(
    model: 'claude-opus-4-6', maxSteps: 20);
const List<String> labels = const [
  'loading',
  'ready',
  'error'
]; // redundant const
```

---

## 4. Tool Definitions

Every tool must implement the `AgentTool` interface. Tool schemas must be
explicit and documented.

### AgentTool Interface

```dart
/// Base interface that every agent tool must implement.
abstract interface class AgentTool {
  /// Unique name used by the model to invoke this tool.
  String get name;

  /// Human-readable description that guides the model on when to use the tool.
  String get description;

  /// JSON Schema describing the tool's input parameters.
  Map<String, dynamic> get inputSchema;

  /// Executes the tool with the given [input] and returns a string result.
  Future<String> execute(Map<String, dynamic> input);

  /// Returns the tool definition map for the API request.
  Map<String, dynamic> toApiMap() =>
      {
        'name': name,
        'description': description,
        'input_schema': inputSchema,
      };
}
```

### Implementing a Tool

```dart
/// Searches the web for current information.
class WebSearchTool implements AgentTool {
  final WebSearchClient _client;

  const WebSearchTool(this._client);

  @override
  String get name => 'search_web';

  @override
  String get description =>
      'Search the internet for current information. '
          'Use when you need facts that may have changed recently '
          'or that are outside your training knowledge.';

  @override
  Map<String, dynamic> get inputSchema =>
      {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': 'The search query string.',
          },
          'maxResults': {
            'type': 'integer',
            'description': 'Number of results to return. Default is 5.',
            'default': 5,
          },
        },
        'required': ['query'],
      };

  @override
  Future<String> execute(Map<String, dynamic> input) async {
    final query = input['query'] as String;
    final maxResults = (input['maxResults'] as int?) ?? 5;
    return _client.search(query, maxResults: maxResults);
  }
}
```

---

## 5. Agent Class Structure

### BaseAgent

```dart
/// Abstract base class for all agents.
///
/// Subclasses must implement [callModel] and may override [executeToolCall].
abstract class BaseAgent {
  BaseAgent({
    required this.model,
    required this.tools,
    required this.systemPrompt,
    this.maxSteps = 20,
  }) : _toolRegistry = ToolRegistry(tools);

  final String model;
  final List<AgentTool> tools;
  final String systemPrompt;
  final int maxSteps;

  final ToolRegistry _toolRegistry;
  final List<Message> trajectory = [];

  /// Runs the agent with the given [userInput] and returns the final response.
  Future<String> run(String userInput);

  /// Makes a single call to the model with the current [messages].
  Future<AgentResponse> callModel(List<Message> messages);

  /// Executes a tool call and returns the string result.
  Future<String> executeToolCall(String toolName, Map<String, dynamic> input) {
    return _toolRegistry.execute(toolName, input);
  }

  /// Formats a tool result for appending to the trajectory.
  Message formatToolResult(String toolUseId, String result) {
    return Message.toolResult(toolUseId: toolUseId, content: result);
  }

  /// Resets the agent's conversation history.
  void reset() => trajectory.clear();
}
```

### Concrete Agent

```dart
class ResearchAgent extends BaseAgent {
  ResearchAgent({
    required super.tools,
    required super.systemPrompt,
    String model = defaultModel,
    int maxSteps = 20,
  }) : super(model: model, maxSteps: maxSteps);

  @override
  Future<String> run(String userInput) async {
    trajectory.add(Message.user(userInput));

    for (var step = 0; step < maxSteps; step++) {
      final response = await callModel(trajectory);
      trajectory.add(Message.assistant(response.content));

      if (response.stopReason == StopReason.endTurn) {
        return response.textContent;
      }

      if (response.stopReason == StopReason.toolUse) {
        for (final toolUse in response.toolUses) {
          final result = await executeToolCall(toolUse.name, toolUse.input);
          trajectory.add(formatToolResult(toolUse.id, result));
        }
        continue;
      }

      throw AgentException(
        'Unexpected stop reason: ${response.stopReason}',
      );
    }

    throw MaxStepsExceededException(
      'Agent exceeded maxSteps ($maxSteps) without completing.',
    );
  }

  @override
  Future<AgentResponse> callModel(List<Message> messages) async {
    // Implementation calls the Anthropic API
    throw UnimplementedError();
  }
}
```

---

## 6. The Agent Loop

### Rules

- **Always cap iteration** with `maxSteps`. Never use `while (true)`.
- **Raise on exhaustion.** Never silently return an empty string when the loop
  ends.
- **Append to trajectory before checking stop conditions**, not after.
- **Handle all `StopReason` values explicitly.** Use an exhaustive switch or
  throw on unexpected values.

```dart
// ✅ Good — explicit, bounded, all cases handled
for (var step = 0; step < maxSteps; step++) {
final response = await callModel(trajectory);
trajectory.add(Message.assistant(response.content));

switch (response.stopReason) {
case StopReason.endTurn:
return response.textContent;

case StopReason.toolUse:
for (final toolUse in response.toolUses) {
final result = await executeToolCall(toolUse.name, toolUse.input);
trajectory.add(formatToolResult(toolUse.id, result));
}

case StopReason.maxTokens:
throw AgentException('Model hit token limit mid-loop.');

case StopReason.stopSequence:
return response.textContent;
}
}

throw MaxStepsExceededException('Exceeded maxSteps ($maxSteps).');

// ❌ Bad — unbounded, silent failure, no exhaustive handling
while (true) {
final response = await callModel(trajectory);
if (response.stopReason == 'end_turn') {
return response.text ?? ''; // Silent empty return
}
}
```

---

## 7. Error Handling

> **Enforced by:** `avoid_void_async`, `await_only_futures`,
`cancel_subscriptions`, `use_rethrow_when_possible`, `test_types_in_equals`,
`unrelated_type_equality_checks`, `valid_regexps`, `empty_catches`,
`avoid_null_checks_in_equality_operators`, `avoid_returning_null_for_void`,
`avoid_catches_without_on_clauses`, `avoid_catching_errors`

### Exception Hierarchy

```dart
/// Base class for all agent-related exceptions.
class AgentException implements Exception {
  const AgentException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      cause != null
          ? 'AgentException: $message (cause: $cause)'
          : 'AgentException: $message';
}

/// Thrown when a tool cannot be found or its execution fails.
class ToolException extends AgentException {
  const ToolException(super.message, {super.cause, this.toolName});

  final String? toolName;
}

/// Thrown when the tool name is not registered.
class UnknownToolException extends ToolException {
  const UnknownToolException(String toolName)
      : super('Unknown tool: "$toolName"', toolName: toolName);
}

/// Thrown when the agent loop exceeds its step limit.
class MaxStepsExceededException extends AgentException {
  const MaxStepsExceededException(super.message);
}
```

### Tool Error Policy

Catch recoverable tool errors and return them as a string. Let the model decide
how to recover. Re-throw unrecoverable errors.

```dart
@override
Future<String> executeToolCall(String toolName,
    Map<String, dynamic> input,) async {
  final tool = _toolRegistry.find(toolName);

  if (tool == null) {
    // Unknown tool: unrecoverable — the model is hallucinating a tool name
    throw UnknownToolException(toolName);
  }

  try {
    return await tool.execute(input);
  } on TimeoutException {
    // Recoverable: return error so the model can retry or change approach
    return 'Tool "$toolName" timed out. Try a different approach.';
  } on ToolException {
    rethrow; // Unrecoverable: bubble up
  } catch (e) {
    // Recoverable: let the model reason about the failure
    return 'Tool "$toolName" failed: $e';
  }
}
```

### Rethrowing

Use `rethrow` instead of `throw e` when re-raising a caught exception. `rethrow`
preserves the original stack trace; `throw e` resets it.

```dart
// ✅ Good
try {
return await tool.execute(input);
} catch (e) {
log('Tool failed', error: e);
rethrow;
}

// ❌ Bad — resets the stack trace
try {
return await tool.execute(input);
} catch (e) {
log('Tool failed', error: e);
throw e;
}
```

### Never Silently Swallow Exceptions

Never leave a `catch` block empty. At minimum, log the error. An empty catch
hides bugs that are very difficult to trace.

```dart
// ✅ Good
try {
await _service.run(input);
} catch (e) {
log('AgentService.run failed: $e');
rethrow;
}

// ❌ Bad — silent catch
try {
await _service.run(input);
} catch (e) {}
```

### Always Catch Specific Types — Never Bare `catch`

Always use `on ExceptionType catch (e)` to target specific exception types (
`avoid_catches_without_on_clauses`). A bare `catch` (or `catch (e)`) silently
intercepts everything — including framework and platform errors that should
propagate. Only use a bare catch as a last resort at the outermost error
boundary, and document why.

```dart
// ✅ Good — targeted catches
try {
final String result = await tool.execute(input);
return result;
} on TimeoutException catch (e) {
return 'Tool timed out: $e';
} on ToolException {
rethrow;
}

// ❌ Bad — catches everything indiscriminately
try {
final String result = await tool.execute(input);
return result;
} catch (e) {
return 'Failed: $e';
}
```

### Never Catch `Error` Subclasses

Do not catch `Error` or its subclasses (e.g. `AssertionError`, `StateError`,
`TypeError`) (`avoid_catching_errors`). `Error` signals a programming mistake
that should crash loudly during development. Catching it hides bugs.

```dart
// ✅ Good — only catch Exception types
try {
return await _service.run(input);
} on AgentException {
rethrow;
}

// ❌ Bad — catching Error hides programming mistakes
try {
return await _service.run(input);
} on Error catch (e) {
log('Caught error: $e'); // This should be a crash, not a log
}
```

```

### Subscriptions

Always cancel `StreamSubscription` instances when no longer needed (`cancel_subscriptions`). Store subscriptions and dispose them in `close()` or `dispose()`.

```dart
// ✅ Good
class AgentCubit extends Cubit<AgentState> {
  AgentCubit(Stream<AgentEvent> events) : super(AgentInitial()) {
    _subscription = events.listen(_onEvent);
  }

  late final StreamSubscription<AgentEvent> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
```

---

## 8. State & Memory

### Keep State Explicit

Never use global state or static mutable fields. All state belongs to the agent
instance.

```dart
// ✅ Good — instance-scoped
class ResearchAgent extends BaseAgent {
  final List<Message> trajectory = [];
  final ShortTermMemory _memory;
}

// ❌ Bad — global mutable state
List<Message> globalTrajectory = [];
static List<Message> sharedHistory = [];
```

### Memory Types

```dart
/// Stores the active conversation window.
class ShortTermMemory {
  ShortTermMemory({this.maxMessages = 50});

  final int maxMessages;
  final List<Message> _messages = [];

  List<Message> get messages => List.unmodifiable(_messages);

  void add(Message message) {
    _messages.add(message);
    if (_messages.length > maxMessages) {
      // Preserve the system context, trim oldest user/assistant turns
      _trimToLimit();
    }
  }

  void clear() => _messages.clear();

  void _trimToLimit() {
    while (_messages.length > maxMessages) {
      _messages.removeAt(0);
    }
  }
}

/// Long-term memory backed by a vector store or database.
abstract interface class LongTermMemory {
  Future<void> store(String key, String content);

  Future<List<String>> retrieve(String query, {int topK = 5});
}
```

---

## 9. Async Patterns

> **Enforced by:** `await_only_futures`, `avoid_void_async`,
`cancel_subscriptions`

### Always Await or Chain

Never fire-and-forget unless intentional. Mark intentional fire-and-forget with
`unawaited()`.

```dart
import 'dart:async' show unawaited;

// ✅ Good — awaited
final String result = await

executeToolCall(name, input);

// ✅ Good — intentional fire-and-forget, clearly marked
unawaited(logToAnalytics(event));

// ❌ Bad — accidental fire-and-forget
executeToolCall(name, input); // result lost, errors swallowed
```

### Timeouts

Always set timeouts on external calls. Never let an agent loop hang
indefinitely.

```dart
Future<String> executeWithTimeout(AgentTool tool,
    Map<String, dynamic> input, {
      Duration timeout = const Duration(seconds: 30),
    }) async {
  return tool.execute(input).timeout(
    timeout,
    onTimeout: () => 'Tool "${tool.name}" timed out after ${timeout
        .inSeconds}s.',
  );
}
```

### Parallel Tool Calls

When a model returns multiple tool calls in one turn, execute them in parallel.

```dart
// ✅ Good — parallel execution
final results = await
Future.wait
(
response.toolUses.map(
(toolUse) => executeToolCall(toolUse.name, toolUse.input).then(
(result) => formatToolResult(toolUse.id, result),
),
),
);
trajectory.addAll(results);

// ❌ Bad — unnecessary sequential execution
for (final ToolUse toolUse in response.toolUses) {
final String result = await executeToolCall(toolUse.name, toolUse.input);
trajectory.add(formatToolResult(toolUse.id, result));
}
```

### Never Return `void` from `async` Functions at API Boundaries

`async` functions that return `void` swallow errors silently — callers cannot
`await` them and any exception is lost. Return `Future<void>` so callers can
handle errors properly (`avoid_void_async`).

```dart
// ✅ Good
Future<void> run(String input) async {
  await _service.run(input);
}

// ❌ Bad — exceptions silently disappear
void run(String input) async {
  await _service.run(input);
}
```

### Only Await Futures

Only use `await` on `Future` values (`await_only_futures`). Awaiting a
non-Future is a no-op and indicates a logic error.

```dart
// ✅ Good
final String result = await

fetchResult(); // fetchResult returns Future<String>

// ❌ Bad
final String result = await
'
literal string
'; // not a Future
```

---

## 10. Prompts

### Store Prompts as Assets

Never hardcode multi-line prompts as inline Dart strings. Use asset files.

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/prompts/
```

```dart
// prompts/prompt_loader.dart
class PromptLoader {
  static Future<String> load(String name) async {
    return rootBundle.loadString('assets/prompts/$name.txt');
  }
}

// Usage
final String systemPrompt = await
PromptLoader.load
('system_prompt
'
);
```

### Prompt File Conventions

- Use `.txt` extension for plain prompts
- Use `{{variable}}` syntax for interpolation placeholders
- Document all variables at the top of each prompt file

```txt
# assets/prompts/researcher_prompt.txt
# Variables: {{currentDate}}, {{userGoal}}

You are a research assistant helping with: {{userGoal}}

Today's date is {{currentDate}}. Use this to assess the recency of information.
...
```

```dart
String interpolate(String template, Map<String, String> variables) {
  String result = template;
  for (final MapEntry<String, String> entry in variables.entries) {
    result = result.replaceAll('{{${entry.key}}}', entry.value);
  }
  return result;
}
```

---

## 11. Testing

### Test File Structure

Mirror the `lib/` structure in `test/`.

```
test/
  agents/
    research_agent_test.dart
  tools/
    web_search_tool_test.dart
  memory/
    short_term_memory_test.dart
```

### Mock Tools for Agent Tests

```dart
class MockWebSearchTool implements AgentTool {
  final String fixedResponse;
  int callCount = 0;

  MockWebSearchTool({this.fixedResponse = 'Mock search result.'});

  @override
  String get name => 'search_web';

  @override
  String get description => 'Mock web search tool.';

  @override
  Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}};

  @override
  Future<String> execute(Map<String, dynamic> input) async {
    callCount++;
    return fixedResponse;
  }
}
```

### Agent Test Pattern

```dart
void main() {
  group('ResearchAgent', () {
    late ResearchAgent agent;
    late MockModelClient mockClient;
    late MockWebSearchTool mockSearch;

    setUp(() {
      mockSearch = MockWebSearchTool();
      mockClient = MockModelClient();
      agent = ResearchAgent(
        tools: [mockSearch],
        systemPrompt: 'You are a test agent.',
        client: mockClient,
      );
    });

    test('returns text response on end_turn', () async {
      mockClient.stubResponse(AgentResponse(
        stopReason: StopReason.endTurn,
        textContent: 'Done.',
        content: [],
        toolUses: [],
      ));

      final result = await agent.run('Hello');

      expect(result, equals('Done.'));
      expect(agent.trajectory, hasLength(2)); // user + assistant
    });

    test('throws MaxStepsExceededException when loop runs too long', () async {
      // Stub model to always return tool_use (infinite loop scenario)
      mockClient.stubRepeatingToolUse('search_web', {'query': 'test'});

      expect(
            () => agent.run('Research something'),
        throwsA(isA<MaxStepsExceededException>()),
      );
    });

    test('executes tools and feeds results back', () async {
      mockClient.stubSequence([
        AgentResponse.toolUse('search_web', {'query': 'Dart'}),
        AgentResponse.endTurn('Here is what I found.'),
      ]);

      final result = await agent.run('Search for Dart.');

      expect(result, equals('Here is what I found.'));
      expect(mockSearch.callCount, equals(1));
    });
  });
}
```

---

## 12. Documentation

> **Enforced by:** `slash_for_doc_comments`, `flutter_style_todos`

### Public APIs

Every public class, method, and field must have a doc comment using `///` —
never `/* */` (`slash_for_doc_comments`).

TODOs must follow the Flutter style: `// TODO(username): description` (
`flutter_style_todos`).

```dart
// ✅ Good — Flutter style TODO
// TODO(alice): add retry logic for transient network failures

// ❌ Bad
// TODO: fix this
// TODO - fix this
```

```dart
/// An agent that performs multi-step research using web search tools.
///
/// The agent will iteratively search the web, reason about results,
/// and compile a final answer. It is bounded by [maxSteps] iterations.
///
/// Example:
/// ```dart
/// final agent = ResearchAgent(
///   tools: [WebSearchTool(client)],
///   systemPrompt: await PromptLoader.load('researcher_prompt'),
/// );
/// final answer = await agent.run('What is the latest on Dart 4?');
/// ```
class ResearchAgent extends BaseAgent {
  /// Maximum number of model + tool iterations before throwing.
  ///
  /// Defaults to 20. Increase for complex, multi-step tasks.
  final int maxSteps;

  /// Runs the agent with [userInput] and returns the final answer.
  ///
  /// Throws [MaxStepsExceededException] if the agent does not reach
  /// a terminal state within [maxSteps] iterations.
  @override
  Future<String> run(String userInput) async {}
}
```

### Private Implementation

For private methods and complex logic, use inline comments to explain *why*, not
*what*.

```dart
// Trim from the front of the trajectory to stay within the context window.
// We never remove the first message (system context).
void _trimToLimit() {
  while (_messages.length > maxMessages) {
    _messages.removeAt(0);
  }
}
```

---

## 13. BLoC Rules

### `emit` Must Only Be Called from Within the Cubit

In a `Cubit`, `emit` is a protected instance method inherited from `BlocBase`.
You call it directly inside the Cubit's own methods to push a new state. It
requires no parameter passing — it is simply part of the Cubit itself.

The compile error below occurs when someone extracts logic into a helper class,
passes the cubit in, and tries to call `emit` on it from outside:

```
The member 'emit' can only be used within instance members of subclasses of 'BlocBase'.
```

**Bad — calling `emit` from an external helper class:**

```dart
// ❌ Bad — AgentRunner is NOT a subclass of BlocBase
class AgentRunner {
  final AgentCubit _cubit;

  AgentRunner(this._cubit);

  Future<void> run(String input) async {
    final String result = await _callModel(input);
    _cubit.emit(
        AgentSuccess(result)); // Compile error: emit is inaccessible here
  }
}
```

Even though `_cubit` is an instance of `AgentCubit`, `emit` is protected — it
can only be called from within the Cubit's own instance methods, not from the
outside.

**Good — keep `emit` inside the Cubit, delegate pure work to services:**

```dart
// ✅ Good — AgentService does pure work and returns a result
class AgentService {
  Future<String> run(String input) async {
    return _callModel(input);
  }
}

// ✅ Good — emit is called directly inside the Cubit's own method
class AgentCubit extends Cubit<AgentState> {
  AgentCubit(this._service) : super(AgentInitial());

  final AgentService _service;

  Future<void> run(String input) async {
    emit(AgentLoading());
    try {
      final String result = await _service.run(input);
      emit(AgentSuccess(result));
    } catch (e) {
      emit(AgentFailure(e.toString()));
    }
  }
}
```

### Rule Summary

| Rule             | Detail                                                   |
|------------------|----------------------------------------------------------|
| `emit` scope     | Only callable inside the Cubit's own instance methods    |
| External classes | Must never receive a cubit and call `emit` on it         |
| Services & tools | Perform pure work and return values — never touch `emit` |
| State changes    | Always initiated from within the Cubit itself            |

---

## Quick Reference

| Convention       | Rule                                                                     |
|------------------|--------------------------------------------------------------------------|
| Agent class      | `PascalCase` + `Agent` suffix                                            |
| Tool class       | `PascalCase` + `Tool` suffix                                             |
| Tool methods     | `camelCase` with verb prefix                                             |
| Constants        | `camelCase` (Dart standard)                                              |
| Files            | `snake_case.dart`                                                        |
| Max steps        | Always set; never use `while (true)`                                     |
| Tool errors      | Return as string unless unrecoverable                                    |
| Parallel tools   | Use `Future.wait()`                                                      |
| Prompts          | Store in `assets/prompts/`, never inline                                 |
| Types            | Always annotate explicitly — never use `var`                             |
| `dynamic`        | Only when type is genuinely undetermined (e.g. raw JSON)                 |
| `final`          | Default for all non-reassigned variables                                 |
| `emit`           | Only inside the Cubit's own methods — never called from external classes |
| Services & tools | Return values only — never receive a cubit or call `emit`                |

---

## 14. Linter Rules Reference

This project extends `package:flutter_lints/flutter.yaml` with the additional
rules below. All rules are enforced by the static analyser — run
`flutter analyze` to check. The table maps each rule to the section of this
document where it is explained.

| Rule                                         | What it enforces                                                   | Section           |
|----------------------------------------------|--------------------------------------------------------------------|-------------------|
| `always_declare_return_types`                | Every function and method must have an explicit return type        | §1 Naming         |
| `always_put_control_body_on_new_line`        | `if`/`else`/`for` bodies always on a new line                      | §3 Formatting     |
| `always_specify_types`                       | Explicit types everywhere — no `var`, no inferred generics         | §3 Formatting     |
| `annotate_overrides`                         | All overriding methods must have `@override`                       | §5 Agent Class    |
| `avoid_catches_without_on_clauses`           | Always catch specific exception types — never use bare `catch`     | §7 Error Handling |
| `avoid_catching_errors`                      | Never catch `Error` subclasses — they signal programming bugs      | §7 Error Handling |
| `avoid_classes_with_only_static_members`     | Use top-level functions instead                                    | §3 Formatting     |
| `avoid_empty_else`                           | No empty `else {}` blocks                                          | §3 Formatting     |
| `avoid_field_initializers_in_const_classes`  | Use constructor initializer lists in const classes                 | §3 Formatting     |
| `avoid_function_literals_in_foreach_calls`   | Use `for` loops instead of `.forEach((x) => ...)`                  | §3 Formatting     |
| `avoid_init_to_null`                         | Don't explicitly initialize to `null` — it is the default          | §3 Formatting     |
| `avoid_null_checks_in_equality_operators`    | Don't manually check for `null` in `==` operators                  | §7 Error Handling |
| `avoid_relative_lib_imports`                 | Use `package:` imports for files inside `lib/`                     | §3 Formatting     |
| `avoid_renaming_method_parameters`           | Keep parameter names consistent with the parent                    | §1 Naming         |
| `avoid_return_types_on_setters`              | Setters must not declare a return type                             | §1 Naming         |
| `avoid_returning_null_for_void`              | Don't return `null` from a `void` function                         | §7 Error Handling |
| `avoid_types_as_parameter_names`             | Don't use type names (e.g. `String`) as parameter names            | §3 Formatting     |
| `avoid_unused_constructor_parameters`        | Remove constructor parameters that are never used                  | §3 Formatting     |
| `avoid_void_async`                           | `async` functions must return `Future<void>`, not `void`           | §9 Async          |
| `await_only_futures`                         | Only `await` actual `Future` values                                | §9 Async          |
| `camel_case_types`                           | Classes, enums, typedefs use `PascalCase`                          | §1 Naming         |
| `cancel_subscriptions`                       | Always cancel `StreamSubscription`                                 | §7 Error Handling |
| `control_flow_in_finally`                    | No `return`/`continue`/`break` inside `finally`                    | §3 Formatting     |
| `directives_ordering`                        | Imports follow: dart → flutter → packages → local                  | §3 Formatting     |
| `empty_catches`                              | No empty `catch` blocks                                            | §7 Error Handling |
| `empty_constructor_bodies`                   | Use `;` instead of `{}` for empty constructors                     | §3 Formatting     |
| `empty_statements`                           | No lone semicolons as empty statements                             | §3 Formatting     |
| `flutter_style_todos`                        | TODOs must be `// TODO(username): description`                     | §12 Documentation |
| `hash_and_equals`                            | Always override `hashCode` when overriding `==`                    | §3 Formatting     |
| `implementation_imports`                     | Never import from another package's `src/`                         | §3 Formatting     |
| `library_names`                              | Library names use `lowercase_with_underscores`                     | §1 Naming         |
| `library_prefixes`                           | Library prefixes use `lowercase_with_underscores`                  | §1 Naming         |
| `no_adjacent_strings_in_list`                | No two adjacent string literals in a list (likely a bug)           | §3 Formatting     |
| `no_duplicate_case_values`                   | No duplicate values in `switch` cases                              | §6 Agent Loop     |
| `non_constant_identifier_names`              | Variables, parameters, functions use `camelCase`                   | §1 Naming         |
| `overridden_fields`                          | Don't re-declare fields that are already in the parent             | §3 Formatting     |
| `package_names`                              | Package names use `lowercase_with_underscores`                     | §1 Naming         |
| `package_prefixed_library_names`             | Library names are prefixed with the package name                   | §1 Naming         |
| `parameter_assignments`                      | Never reassign a parameter — use a new local variable instead      | §3 Formatting     |
| `prefer_adjacent_string_concatenation`       | Use adjacent literals, not `+`, for compile-time concatenation     | §3 Formatting     |
| `prefer_asserts_in_initializer_lists`        | Put `assert` calls in the constructor initializer list             | §5 Agent Class    |
| `prefer_collection_literals`                 | Use `[]`, `{}`, `<>{}` instead of constructors                     | §3 Formatting     |
| `prefer_conditional_assignment`              | Use `??=` instead of `if (x == null) x = ...`                      | §3 Formatting     |
| `prefer_const_constructors`                  | Use `const` constructors wherever possible                         | §3 Formatting     |
| `prefer_const_constructors_in_immutables`    | `@immutable` classes must declare all constructors as `const`      | §3 Formatting     |
| `prefer_const_declarations`                  | Use `const` for compile-time constant top-level/static variables   | §3 Formatting     |
| `prefer_const_literals_to_create_immutables` | Use `const` list/map literals in immutable constructors            | §3 Formatting     |
| `prefer_contains`                            | Use `.contains()` instead of `.indexOf() != -1`                    | §3 Formatting     |
| `prefer_final_fields`                        | Class fields that are never reassigned must be `final`             | §3 Formatting     |
| `prefer_final_locals`                        | Local variables that are never reassigned must be `final`          | §3 Formatting     |
| `prefer_foreach`                             | Use `.forEach()` for single-statement iterations (when not async)  | §3 Formatting     |
| `prefer_generic_function_type_aliases`       | Use `typedef F = void Function()` syntax                           | §3 Formatting     |
| `prefer_initializing_formals`                | Use `this.field` in constructors instead of manual assignment      | §3 Formatting     |
| `prefer_is_empty`                            | Use `.isEmpty` instead of `.length == 0`                           | §3 Formatting     |
| `prefer_is_not_empty`                        | Use `.isNotEmpty` instead of `.length > 0`                         | §3 Formatting     |
| `prefer_iterable_whereType`                  | Use `.whereType<T>()` instead of `.where((x) => x is T).cast<T>()` | §3 Formatting     |
| `prefer_single_quotes`                       | Use single quotes for strings                                      | §3 Formatting     |
| `prefer_typing_uninitialized_variables`      | Always declare a type for uninitialized variables                  | §3 Formatting     |
| `prefer_void_to_null`                        | Use `void` instead of `Null` for functions that return nothing     | §7 Error Handling |
| `recursive_getters`                          | Getters must not call themselves recursively                       | §5 Agent Class    |
| `slash_for_doc_comments`                     | Use `///` for doc comments, never `/** */`                         | §12 Documentation |
| `sort_constructors_first`                    | Constructors come before other members in a class                  | §3 Formatting     |
| `sort_pub_dependencies`                      | Dependencies in `pubspec.yaml` are alphabetically sorted           | §2 Structure      |
| `sort_unnamed_constructors_first`            | Unnamed constructors come before named constructors                | §3 Formatting     |
| `test_types_in_equals`                       | Use `is` checks rather than equality on `Type` objects             | §7 Error Handling |
| `throw_in_finally`                           | Never throw inside a `finally` block                               | §3 Formatting     |
| `type_init_formals`                          | Don't re-specify the type in initializing formals                  | §3 Formatting     |
| `unnecessary_brace_in_string_interps`        | Use `$variable` not `${variable}` for simple identifiers           | §3 Formatting     |
| `unnecessary_const`                          | Don't add `const` inside a `const` context                         | §3 Formatting     |
| `unnecessary_getters_setters`                | Replace trivial getter/setter pairs with a plain field             | §5 Agent Class    |
| `unnecessary_new`                            | Never use the `new` keyword                                        | §3 Formatting     |
| `unnecessary_null_aware_assignments`         | Don't use `??=` when the value can never be null                   | §3 Formatting     |
| `unnecessary_null_in_if_null_operators`      | Don't write `x ?? null`                                            | §3 Formatting     |
| `unnecessary_overrides`                      | Don't override a method just to call `super` with the same args    | §5 Agent Class    |
| `unnecessary_parenthesis`                    | Remove redundant parentheses                                       | §3 Formatting     |
| `unnecessary_statements`                     | Remove expressions used as statements that have no effect          | §3 Formatting     |
| `unnecessary_this`                           | Don't qualify with `this.` unless there is a name clash            | §3 Formatting     |
| `unrelated_type_equality_checks`             | Don't compare values of unrelated types with `==`                  | §7 Error Handling |
| `use_rethrow_when_possible`                  | Use `rethrow` instead of `throw e` to preserve stack traces        | §7 Error Handling |
| `valid_regexps`                              | All `RegExp` string literals must be valid patterns                | §7 Error Handling |