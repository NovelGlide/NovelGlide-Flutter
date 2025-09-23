part of '../homepage.dart';

class HomepageCompactView extends StatelessWidget {
  const HomepageCompactView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: const HomepageAppBarBuilder(),
      body: const Column(
        children: <Widget>[
          Advertisement(
            unitId: AdUnitId.homepageCompact,
          ),
          Expanded(
            child: HomepageScaffoldBody(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 80.0,
          margin: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36.0),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withAlpha(50),
                blurRadius: 16.0,
                offset: const Offset(0.0, 8.0),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: const HomepageNavigationBar(),
        ),
      ),
      floatingActionButton: const HomepageFloatingActionWidget(),
    );
  }
}
