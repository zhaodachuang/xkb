import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ui/application/messages/processed/processed_bloc.dart';

class ProcessedManageNo extends StatelessWidget {
  final AnimationController animationController;
  final Animation animation;

  const ProcessedManageNo({
    Key key,
    this.animationController,
    this.animation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProcessedBloc, ProcessedState>(
        builder: (context, state) {
      return AnimatedBuilder(
        animation: animationController,
        builder: (BuildContext context, Widget child) {
          return FadeTransition(
            opacity: animation,
            child: new Transform(
              transform: new Matrix4.translationValues(
                  0.0, 30 * (1.0 - animation.value), 0.0),
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 24, right: 24, top: 16, bottom: 18),
                child: Container(
                  // decoration: BoxDecoration(
                  //   gradient: LinearGradient(colors: [
                  //     FitnessAppTheme.nearlyDarkBlue,
                  //     HexColor("#6F56E8")
                  //   ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  //   borderRadius: BorderRadius.only(
                  //       topLeft: Radius.circular(8.0),
                  //       bottomLeft: Radius.circular(8.0),
                  //       bottomRight: Radius.circular(8.0),
                  //       topRight: Radius.circular(68.0)),
                  //   boxShadow: <BoxShadow>[
                  //     BoxShadow(
                  //         color: FitnessAppTheme.grey.withOpacity(0.6),
                  //         offset: Offset(1.1, 1.1),
                  //         blurRadius: 10.0),
                  //   ],
                  // ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (state.processedData.containsKey("managerDeration"))
                          Row(
                            children: [
                              Container(
                                child: Text("?????????"),
                              ),
                              Expanded(
                                child: Container(
                                  child: Text(
                                      state.processedData["managerDeration"]
                                          ["value"]),
                                ),
                              ),
                            ],
                          ),
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                child: SizedBox(),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
