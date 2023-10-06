import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const Scaffold(body: HomeView()),
      ),
    );
  }
}

class HomeModel extends ViewModel {
  List<String> items = ['Item 1', 'Item 2', 'Item 3'];
}

class HomeView extends AppView<HomeController, HomeModel> {
  const HomeView({super.key});

  @override
  HomeController controllerBuilder() => HomeController();

  @override
  HomeModel modelBuilder(BuildContext context) => HomeModel();

  @override
  Widget build(HomeController controller, HomeModel model) {
    return ListView.builder(
      itemCount: model.items.length,
      itemBuilder: (context, index) {
        print("Building $index");
        return ListItemView(
          item: model.items[index],
          index: index,
        );
      },
    );
  }
}

class HomeController extends ViewController<HomeModel> {
  void addItem() {
    model.items.add('New Item ${model.items.length + 1}');
    rebuildView();
  }

  void invertItem() {
    model.items.shuffle();
    rebuildView();
  }
}

class ListItemModel extends ViewModel {
  String item;
  String width;

  ListItemModel({required this.item, required this.width});
}

class ListItemView extends AppView<ListItemController, ListItemModel> {
  final String item;
  final int index;

  const ListItemView({required this.item, required this.index, Key? key})
      : super(key: key);

  @override
  ListItemController controllerBuilder() => ListItemController();

  @override
  ListItemModel modelBuilder(BuildContext context) => ListItemModel(
      item: item, width: MediaQuery.of(context).size.width.toString());

  @override
  Widget build(ListItemController controller, ListItemModel model) {
    return ListTile(
      title: Text(model.item),
      subtitle: Text('Width: ${model.width}'),
      trailing: index % 2 == 0
          ? ElevatedButton(
              onPressed: controller.updateItem,
              child: const Text('Update Item'),
            )
          : ElevatedButton(
              onPressed: controller.addItem, child: const Text("Add item")),
    );
  }
}

class ListItemController extends ViewController<ListItemModel> {
  void updateItem() {
    model.item += ' Updated';
    rebuildView();
  }

  HomeController get parent => controller();
  void addItem() => parent.addItem();
  void invertItem() => parent.invertItem();

  @override
  void dependencyChanged(BuildContext context) {
    model.width = MediaQuery.of(context).size.width.toString();
    rebuildView();
  }
}

class ControllerProvider<C> extends InheritedWidget {
  final C controller;

  const ControllerProvider(
      {super.key, required this.controller, required Widget child})
      : super(child: child);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}

class ViewModel {}

abstract class AppView<C extends ViewController<M>, M extends ViewModel>
    extends Widget {
  C controllerBuilder();
  M modelBuilder(BuildContext context);

  const AppView({super.key});

  Widget build(C controller, M model);

  @override
  ControllerElement<C, M, AppView<C, M>> createElement() =>
      ControllerElement<C, M, AppView<C, M>>(this);
}

class ControllerElement<C extends ViewController<M>, M extends ViewModel,
    X extends AppView<C, M>> extends ComponentElement {
  C? controller;

  ControllerElement(X super.widget);

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    controller!.init();
  }

  @override
  void attachNotificationTree() {
    if (controller == null) {
      controller = (widget as X).controllerBuilder().._elt = this;
      controller!._model = (widget as X).modelBuilder(this);
    }
    super.attachNotificationTree();
  }

  void _cleanController() {
    controller!.dispose();
    controller!._elt = null;
    controller!._model = null;
    controller = null;
  }

  @override
  void unmount() {
    _cleanController();
    super.unmount();
  }

  @override
  // ignore: must_call_super
  void didChangeDependencies() {
    controller!.dependencyChanged(this);
  }

  @override
  void update(covariant X newWidget) {
    super.update(newWidget);
    _cleanController();
    controller = newWidget.controllerBuilder().._elt = this;
    controller!._model = newWidget.modelBuilder(this);
    assert(widget == newWidget);
    rebuild(force: true);
  }

  @override
  Widget build() {
    return ControllerProvider<C>(
        controller: controller!,
        child: (widget as X).build(controller!, controller!._model!));
  }
}

abstract class ViewController<T extends ViewModel> {
  ControllerElement? _elt;
  void rebuildView() => _elt!.markNeedsBuild();
  late T? _model;
  T get model => _model as T;
  void init() {}
  void dependencyChanged(BuildContext context) {
    rebuildView();
  }

  C controller<C extends ViewController>() => _elt!
      .dependOnInheritedWidgetOfExactType<ControllerProvider<C>>()!
      .controller;

  void dispose() {}
}

class ModelScope<M extends Model> extends InheritedModel {
  const ModelScope({super.key, required super.child});

  @override
  bool updateShouldNotify(covariant ModelScope oldWidget) => true;

  @override
  bool updateShouldNotifyDependent(
      covariant ModelScope oldWidget, Set dependencies) {
    throw UnimplementedError();
  }
}

class Model {
  bool notifyUpdate(covariant Model old) => true;
  bool notifyUpdateDependdent(covariant Model old, Set deps) => true;
}

class MyModel extends Model {}

abstract class BaseView<M extends ModelScope> extends Widget {
  M modelBuilder(BuildContext context);
  const BaseView({super.key});

  Widget build();
}

class Rx<T> {
  T? value;
  Rx([this.value]);
}

class User {}

class StateObserver {}

abstract class SharedState<T extends StateObserver> {
  late final T obs = createObserver();
  T createObserver();
}

class AppObserver extends StateObserver {}

class AppState extends SharedState<AppObserver> {
  @override
  AppObserver createObserver() => AppObserver();
}
