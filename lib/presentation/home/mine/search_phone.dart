import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ui/application/mine/bloc/mine_bloc.dart';
import 'package:flutter_ui/injection.dart';

class SearchPhone extends StatefulWidget {
  @override
  _SearchPhoneState createState() => _SearchPhoneState();
}

class _SearchPhoneState extends State<SearchPhone> {
  String _textFeid = "";
  List _searchList = [];
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (BuildContext context) => getIt<MineBloc>(),
        child:
            BlocConsumer<MineBloc, MineState>(listener: (context, state) async {
          setState(() {
            _searchList = state.matchPhone;
          });
        }, builder: (BuildContext context, state) {
          return Listener(
            onPointerDown: (onPointerDown) {
              FocusScope.of(context).requestFocus(FocusNode());
              print('手指按下回调');
            },
            child: Scaffold(
              appBar: AppBar(
                  title: Text("查询", style: TextStyle(color: Colors.grey[700])),
                  elevation: 0.0,
                  brightness: Brightness.light,
                  backgroundColor: Colors.white,
                  iconTheme: IconThemeData(color: Colors.grey[700])),
              body: Padding(
                padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                child: Column(
                  children: [
                    searchHeader(context),
                    Expanded(
                      child: content(_searchList),
                    )
                  ],
                ),
              ),
            ),
          );
        }));
  }

  searchHeader(context) {
    return Row(
      children: [
        Expanded(
          child: Container(
              height: 50,
              child: Container(
                height: 45.0,
                margin: EdgeInsets.fromLTRB(0, 0, 10, 5),
                padding: EdgeInsets.fromLTRB(10, 5, 0, 0),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200]),
                child: TextField(
                  maxLines: 1,
                  textInputAction: TextInputAction.go,
                  decoration: InputDecoration(
                    hintText: "搜索电话(精准查询)",
                    prefixIcon:
                        Icon(Icons.search, color: Colors.grey[500], size: 20),
                    border: InputBorder.none,
                    isDense: true,
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                  // keyboardType: TextInputType.number,
                  controller: TextEditingController.fromValue(
                    TextEditingValue(
                      text: _textFeid,
                      selection: TextSelection.fromPosition(TextPosition(
                        affinity: TextAffinity.downstream,
                        offset: _textFeid.length,
                      )),
                    ),
                  ),
                  onChanged: (val) {
                    _textFeid = val;
                  },
                ),
              )),
        ),
        Container(
          width: 65,
          height: 35,
          child: RaisedButton(
            onPressed: () {
              if (_textFeid.length != 11) {
                BotToast.showText(text: "请输入正确电话");
              } else {
                BlocProvider.of<MineBloc>(context)
                    .add(MineEvent.getMatchingPhone(_textFeid));
              }
            },
            child: Text(
              "搜索",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            textColor: Colors.white,
            color: Colors.blue[500],
            elevation: 2,
          ),
        )
      ],
    );
  }

  content(List list) {
    return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, i) => Container(
              height: 45,
              margin: EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[500],
                    blurRadius: 1.0,
                  ),
                ],
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Container(
                  //     margin: EdgeInsets.only(left: 10, top: 2),
                  //     child: Row(
                  //       children: [
                  //         Text(
                  //           "租户信息:",
                  //           style: TextStyle(
                  //               color: Colors.grey[800], fontSize: 15),
                  //         ),
                  //         SizedBox(width: 15),
                  //         Text(
                  //           list[i]["tentId"],
                  //           // maxLines: 1,
                  //           // overflow: TextOverflow.ellipsis,
                  //           style: TextStyle(
                  //               color: Colors.grey[500], fontSize: 15),
                  //         ),
                  //       ],
                  //     )),
                  Container(
                    margin: EdgeInsets.only(left: 10, top: 2),
                    child: Row(
                      children: [
                        Text(
                          "电话号码:",
                          style:
                              TextStyle(color: Colors.grey[800], fontSize: 15),
                        ),
                        SizedBox(width: 15),
                        Text(
                          list[i],
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 15),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ));
  }
}
