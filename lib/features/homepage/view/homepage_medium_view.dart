part of '../homepage.dart';

class HomepageMediumView extends StatelessWidget {
  const HomepageMediumView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: const HomepageAppBarBuilder(),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.fromLTRB(8.0, 0.0, 16.0, 8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36.0),
                color: Theme.of(context).colorScheme.surfaceContainer,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withAlpha(50),
                    blurRadius: 16.0,
                    offset: const Offset(0.0, 8.0),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: const HomepageNavigationRail(),
            ),
            Expanded(
              child: Stack(
                children: <Widget>[
                  const HomepageScaffoldBody(),
                  Positioned(
                    left: 0.0,
                    bottom: 0.0,
                    child: SizedBox(
                      width: WindowSize.compact.maxWidth,
                      child: const Advertisement(
                        unitId: AdUnitId.homepageMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const HomepageFloatingActionWidget(),
    );
  }
}
