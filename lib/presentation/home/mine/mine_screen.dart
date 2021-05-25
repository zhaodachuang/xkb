import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ui/application/mine/bloc/mine_bloc.dart';
import 'package:flutter_ui/injection.dart';
import 'package:flutter_ui/presentation/core/fintness_app_theme.dart';
import 'package:flutter_ui/presentation/home/ui_view/mine_about_us_view.dart';
import 'package:flutter_ui/presentation/home/ui_view/mine_achievement_view.dart';
import 'package:flutter_ui/presentation/home/ui_view/mine_aiCard_view.dart';
import 'package:flutter_ui/presentation/home/ui_view/mine_change_project_view.dart';
import 'package:flutter_ui/presentation/home/ui_view/mine_consultation_view.dart';
import 'package:flutter_ui/presentation/home/ui_view/mine_guest_phone_view.dart';
import 'package:flutter_ui/presentation/home/ui_view/mine_online_service_view.dart';
import 'package:flutter_ui/presentation/home/ui_view/mine_order_view.dart';
import 'package:flutter_ui/presentation/home/ui_view/mine_ownership_plan_view.dart';
import 'package:flutter_ui/presentation/home/ui_view/mine_suggest_feedback_view.dart';
import 'package:flutter_ui/presentation/home/ui_view/wechat.dart';
import 'package:flutter_ui/presentation/home/ui_view/wechat_new_view.dart';
import 'package:flutter_ui/presentation/home/ui_view/wechat_view.dart';
import 'package:flutter_ui/presentation/routes/router.gr.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MineScreen extends StatefulWidget {
  const MineScreen({Key key, this.animationController}) : super(key: key);
  final AnimationController animationController;

  @override
  _MineScreenState createState() => _MineScreenState();
}

class _MineScreenState extends State<MineScreen> with TickerProviderStateMixin {
  Animation<double> topBarAnimation;

  List<Widget> listViews = <Widget>[];
  final ScrollController scrollController = ScrollController();
  double topBarOpacity = 0.0;
  List _listHouse = [];
  List _listHouseId = [];
  List _listHouseShortCode = [];
  String _house = "";
  String _cachedSignInUser = "";

  @override
  void initState() {
    topBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: widget.animationController,
            curve: Interval(0, 0.5, curve: Curves.fastOutSlowIn)));
    addAllListData();

    scrollController.addListener(() {
      if (scrollController.offset >= 24) {
        if (topBarOpacity != 1.0) {
          setState(() {
            topBarOpacity = 1.0;
          });
        }
      } else if (scrollController.offset <= 24 &&
          scrollController.offset >= 0) {
        if (topBarOpacity != scrollController.offset / 24) {
          setState(() {
            topBarOpacity = scrollController.offset / 24;
          });
        }
      } else if (scrollController.offset <= 0) {
        if (topBarOpacity != 0.0) {
          setState(() {
            topBarOpacity = 0.0;
          });
        }
      }
    });
    super.initState();
  }

  void addAllListData() {
    const int count = 5;

    listViews.add(BlocBuilder<MineBloc, MineState>(builder: (context, state) {
      return MineChangeProjectView(
        house: _house,
        listHouse: _listHouse,
        listHouseId: _listHouseId,
        listHouseShortCode: _listHouseShortCode,
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: widget.animationController,
            curve:
                Interval((1 / count) * 1, 1.0, curve: Curves.fastOutSlowIn))),
        animationController: widget.animationController,
      );
    }));

    // listViews.add(
    //   MineConsultationView(
    //     animation: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
    //         parent: widget.animationController,
    //         curve:
    //             Interval((1 / count) * 2, 1.0, curve: Curves.fastOutSlowIn))),
    //     animationController: widget.animationController,
    //   ),
    // );
    listViews.add(
      MineAiCardView(
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: widget.animationController,
            curve:
                Interval((1 / count) * 2, 1.0, curve: Curves.fastOutSlowIn))),
        animationController: widget.animationController,
      ),
    );
    listViews.add(
      MineAchievementView(
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: widget.animationController,
            curve:
                Interval((1 / count) * 3, 1.0, curve: Curves.fastOutSlowIn))),
        animationController: widget.animationController,
      ),
    );
    // listViews.add(
    //   MineOrder(
    //     animation: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
    //         parent: widget.animationController,
    //         curve:
    //             Interval((1 / count) * 4, 1.0, curve: Curves.fastOutSlowIn))),
    //     animationController: widget.animationController,
    //   ),
    // );
    // listViews.add(
    //   MineGuestPhoneView(
    //     animation: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
    //         parent: widget.animationController,
    //         curve:
    //             Interval((1 / count) * 5, 1.0, curve: Curves.fastOutSlowIn))),
    //     animationController: widget.animationController,
    //   ),
    // );
    // listViews.add(
    //   MineOwnershipPlanView(
    //     animation: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
    //         parent: widget.animationController,
    //         curve:
    //             Interval((1 / count) * 6, 1.0, curve: Curves.fastOutSlowIn))),
    //     animationController: widget.animationController,
    //   ),
    // );
    listViews.add(
      MineSuggestFeedbackView(
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: widget.animationController,
            curve:
                Interval((1 / count) * 4, 1.0, curve: Curves.fastOutSlowIn))),
        animationController: widget.animationController,
      ),
    );
    listViews.add(
      MineAboutUsView(
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: widget.animationController,
            curve:
                Interval((1 / count) * 5, 1.0, curve: Curves.fastOutSlowIn))),
        animationController: widget.animationController,
      ),
    );
    // listViews.add(
    //   WechatView(
    //     animation: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
    //         parent: widget.animationController,
    //         curve:
    //             Interval((1 / count) * 6, 1.0, curve: Curves.fastOutSlowIn))),
    //     animationController: widget.animationController,
    //   ),
    // );
    // listViews.add(
    //   WechatNewView(
    //     animation: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
    //         parent: widget.animationController,
    //         curve:
    //             Interval((1 / count) * 7, 1.0, curve: Curves.fastOutSlowIn))),
    //     animationController: widget.animationController,
    //   ),
    // );
    // listViews.add(
    //   Wechat(
    //     animation: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
    //         parent: widget.animationController,
    //         curve:
    //             Interval((1 / count) * 8, 1.0, curve: Curves.fastOutSlowIn))),
    //     animationController: widget.animationController,
    //   ),
    // );

    // listViews.add(
    //   MineOnlineServiceView(
    //     animation: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
    //         parent: widget.animationController,
    //         curve:
    //             Interval((1 / count) * 8, 1.0, curve: Curves.fastOutSlowIn))),
    //     animationController: widget.animationController,
    //   ),
    // );
  }

  Future<bool> getData() async {
    await Future<dynamic>.delayed(const Duration(milliseconds: 50));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (BuildContext context) =>
            getIt<MineBloc>()..add(const MineEvent.handleProcess()),
        child:
            BlocConsumer<MineBloc, MineState>(listener: (context, state) async {
          SharedPreferences sharedPreferences =
              await SharedPreferences.getInstance();
          _cachedSignInUser = sharedPreferences.get('CACHED_SIGN_IN_USER');
          String affiliateds = sharedPreferences.get('AFFILIATEDS');
          List affidList = [];
          if (affiliateds != null) {
            affidList = jsonDecode(affiliateds);
          }
          for (int i = 0; i < affidList.length; i++) {
            _listHouse.add(affidList[i]["projectName"]);
            _listHouseId.add(affidList[i]["id"]);
            _listHouseShortCode.add(affidList[i]["affiliationCode"]);
          }
          String houseName = sharedPreferences.getString("HOUSESNAME");
          if (houseName == null) {
            sharedPreferences.setString(
                HOUSESNAME, affidList[0]["projectName"]);
            sharedPreferences.setString(HOUSEID, affidList[0]["id"]);
            sharedPreferences.setString(
                HOUSESHORTCODE, affidList[0]["affiliationCode"]);
            _house = affidList[0]["projectName"];
          } else {
            _house = houseName;
          }
        }, builder: (BuildContext context, state) {
          return Container(
            color: FitnessAppTheme.background,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: <Widget>[
                  getMainListViewUI(),
                  getAppBarUI(),
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom,
                  )
                ],
              ),
            ),
          );
        }));
  }

  Widget getMainListViewUI() {
    return FutureBuilder<bool>(
      future: getData(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        } else {
          return ListView.builder(
            controller: scrollController,
            padding: EdgeInsets.only(
              top: AppBar().preferredSize.height +
                  MediaQuery.of(context).padding.top +
                  24,
              bottom: 62 + MediaQuery.of(context).padding.bottom,
            ),
            itemCount: listViews.length,
            scrollDirection: Axis.vertical,
            itemBuilder: (BuildContext context, int index) {
              widget.animationController.forward();
              return listViews[index];
            },
          );
        }
      },
    );
  }

  Widget getAppBarUI() {
    return Column(
      children: <Widget>[
        AnimatedBuilder(
          animation: widget.animationController,
          builder: (BuildContext context, Widget child) {
            return FadeTransition(
              opacity: topBarAnimation,
              child: Transform(
                transform: Matrix4.translationValues(
                    0.0, 30 * (1.0 - topBarAnimation.value), 0.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: FitnessAppTheme.white.withOpacity(topBarOpacity),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32.0),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                          color: FitnessAppTheme.grey
                              .withOpacity(0.4 * topBarOpacity),
                          offset: const Offset(1.1, 1.1),
                          blurRadius: 10.0),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: MediaQuery.of(context).padding.top,
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16 - 8.0 * topBarOpacity,
                            bottom: 12 - 8.0 * topBarOpacity),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            if (_cachedSignInUser != "")
                              InkWell(
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  margin: EdgeInsets.fromLTRB(15, 0, 15, 0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50.0),
                                    image: DecorationImage(
                                        image: NetworkImage(
                                          // 'https://www.itying.com/images/flutter/7.png'
                                          jsonDecode(
                                              _cachedSignInUser)['headimgUrl'],
                                        ),
                                        fit: BoxFit.cover),
                                  ),
                                  child: Text(""),
                                ),
                                onTap: () {
                                  ExtendedNavigator.of(context).push(
                                      Routes.uploadNetImgPreview,
                                      arguments: UploadNetImgPreviewArguments(
                                          img: jsonDecode(_cachedSignInUser)[
                                              'headimgUrl']));
                                },
                              ),
                            if (_cachedSignInUser != "")
                              Text(
                                  // '刘聪',
                                  jsonDecode(_cachedSignInUser)['realName'],
                                  style: TextStyle(
                                      fontSize: 19.0,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700])),
                            if (_cachedSignInUser != "")
                              Container(
                                margin: EdgeInsets.only(left: 10.0),
                                padding: EdgeInsets.all(1.0),
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        width: 1.0, color: Colors.blue),
                                    borderRadius: BorderRadius.circular(5.0)),
                                child: Text(
                                  // '置业顾问',
                                  // jsonDecode(_cachedSignInUser)['userRole'],
                                  _userRole(),
                                  style: TextStyle(
                                      color: Colors.blue, fontSize: 10),
                                ),
                              ),
                            Expanded(child: Text("")),
                            InkWell(
                                child: Container(
                                  width: 90,
                                  height: 60,
                                  child: Icon(
                                    Icons.settings,
                                    color: Colors.grey,
                                  ),
                                ),
                                onTap: () {
                                  ExtendedNavigator.of(context)
                                      .push(Routes.mineSettingPage);
                                }),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        )
      ],
    );
  }

  String _userRole() {
    String userRole = '';
    String userInfo = jsonDecode(_cachedSignInUser)['userRole'];
    switch (userInfo) {
      case 'salesman':
        userRole = '置业顾问';
        return userRole;
      case 'secretary':
        userRole = '销秘';
        return userRole;
      case 'manager':
        userRole = '经理';
        return userRole;
      case 'financial':
        userRole = '财务';
        return userRole;
      case 'director':
        userRole = '总监';
        return userRole;
    }
    return userRole;
  }
}
