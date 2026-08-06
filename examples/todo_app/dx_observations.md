# CubePod DX Observations (Todo App)

## Observations

### 1. Route-Scoped Dependency Boilerplate (Confirmed)
**Observation:**
Just like in the Hacker News app, we had to write the exact same boilerplate to scope the `TodoEditViewModel` to the `/add` and `/edit/:id` routes.
```dart
final child = CubePod.createScope(parent: CubePod.root);
child.register((c) => TodoEditViewModel(...), scope: Scope.scoped);
return CubeScope(container: child, child: const TodoEditScreen());
```
**Conclusion:**
This is definitively a recurring pain point. It appeared in both reference apps. The framework absolutely needs a cleaner wrapper (e.g. `CubeProvider`) for injecting scoped dependencies into the widget tree without manually touching the container instances.

### 2. Consuming UI State (ChangeNotifier) (Confirmed)
**Observation:**
In `TodoListScreen` and `TodoEditScreen`, we again had to use the two-step process:
1. `final viewModel = context.get<TodoListViewModel>();`
2. Wrap parts of the UI in `ListenableBuilder(listenable: viewModel, builder: ...)`
This felt especially cumbersome in the `TodoEditScreen` where we just wanted to disable the save button based on a single property `viewModel.isValid`.
**Conclusion:**
This boilerplate is repetitive and adds unnecessary nesting. We have strong justification for implementing `context.watch<T>()` in the framework.

### 3. Root Application Scope (Confirmed)
**Observation:**
We had to write `CubeScope(container: CubePod.root)` around the `MaterialApp` builder again.
**Conclusion:**
It's minor, but it confirms the hypothesis. A top-level `CubePodProvider` or similar would make the framework feel more idiomatic to Flutter developers.

### 4. Passing Route Parameters to ViewModels (New Friction)
**Observation:**
In the `/edit/:id` route, we needed to pass the `initialTodo` to the `TodoEditViewModel`. Because `FactoryFunc` doesn't take parameters other than the container, we had to resolve the `TodoListViewModel` *before* registering the `TodoEditViewModel`, extract the todo, and pass it via closure:
```dart
final listViewModel = CubePod.get<TodoListViewModel>();
final todo = listViewModel.filteredTodos.firstWhere((t) => t.id == id);
child.register((c) => TodoEditViewModel(c.get<TodoListViewModel>(), initialTodo: todo), scope: Scope.scoped);
```
**Conclusion:**
This isn't necessarily a flaw (closures work perfectly here), but it highlights that passing runtime parameters to dependencies requires manual setup in the routing layer rather than the DI layer itself. This is an observation to keep an eye on.
