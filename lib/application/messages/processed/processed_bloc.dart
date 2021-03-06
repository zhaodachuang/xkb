import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_ui/application/message/bloc/web_scoket_bloc.dart';
import 'package:flutter_ui/domain/house/i_house_facade.dart';
import 'package:flutter_ui/domain/messages/i_message_facade.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ui/domain/coustomer/i_coustomer_facade.dart';

part 'processed_event.dart';
part 'processed_state.dart';
part 'processed_bloc.freezed.dart';

@injectable
class ProcessedBloc extends Bloc<ProcessedEvent, ProcessedState> {
  IMessagesFacade _iMessagesFacade;
  ICoustomerFacade _coustomerFacade;
  SharedPreferences _preferences;
  IHouseFacade _iHouseFacade;
  ProcessedBloc(this._iMessagesFacade, this._preferences, this._iHouseFacade,
      this._coustomerFacade)
      : super(ProcessedState.initial());

  @override
  Stream<ProcessedState> mapEventToState(
    ProcessedEvent event,
  ) async* {
    yield* event.map(
      started: (value) async* {
        print(value);
      },
      getProcessData: (value) async* {
        var user = _preferences.get('CACHED_SIGN_IN_USER');
        yield state.copyWith(userRole: jsonDecode(user)["userRole"]);
        // yield state.copyWith(
        //     userRole: "manager"); //secretary salesman  manager  financial
        var res = await _iMessagesFacade
            .getProcessedData(state.processedItem["processInstanceId"]);
        print(res);
        var salesmanList = await _iMessagesFacade
            .getSalesmanList(res["affiliationId"]["value"]);
        List manlist = [];
        Map<String, dynamic> showsalesMan = {};
        String manName = "";
        var salesManId =
            state.processedItem["taskDefinitionKey"] == "Activity_0fvuxs2"
                ? res["initiator"]["value"]
                : state.processedItem["taskDefinitionKey"] == "Activity_0ossp3s"
                    ? res["initiator"]["value"]
                    : res["salesmanId"]["value"];

        for (var i = 0; i < salesmanList["data"].length; i++) {
          if (jsonDecode(user)["memberGroup"] ==
              salesmanList["data"][i]["memberGroup"]) {
            manlist.add(salesmanList["data"][i]["realName"]);
          }
          if (salesmanList["data"][i]["id"] == salesManId) {
            manName = salesmanList["data"][i]["realName"];
            showsalesMan = salesmanList["data"][i];
          }
        }

        yield state.copyWith(
          processedData: res,
          salesmanMapList: salesmanList["data"],
          salesmanList: manlist,
          manageAssignmentUser: manName,
          showsalesMan: showsalesMan,
        );
      },
      saveData: (value) async* {
        Map<String, dynamic> query = {
          "processInstanceId": value.data["processInstanceId"],
        };
        var res = await _coustomerFacade.gethistory(query);
        // print(res);
        res.sort((a, b) => DateTime.parse(a["startTime"])
            .toLocal()
            .millisecondsSinceEpoch
            .compareTo(DateTime.parse(b["startTime"])
                .toLocal()
                .millisecondsSinceEpoch));
        // print(res);
        var startTime = "";
        if (res.length != 0) {
          startTime = res[0]["startTime"]
              .toString()
              .substring(0, 19)
              .replaceAll('T', ' ');
        }
        yield state.copyWith(processedItem: value.data, startTime: startTime);
      },
      pushProcessed: (value) async* {
        // var user = _preferences.get('CACHED_SIGN_IN_USER');
        // yield state.copyWith(changTextColor: true);
        // print(user);
        String type = value.type;
        String userRole = state.userRole;
        print(userRole);
        switch (userRole) {
          case 'secretary': //??????

            var res = await _iMessagesFacade.processFlow(
                state.groupValue, state.processedItem["id"]);
            print("??????res");
            print(res);
            yield state.copyWith(processResult: res);
            break;
          case 'salesman': //????????????
            var query;
            switch (state.processedItem["taskDefinitionKey"]) {
              case "CategoryManagent":
                var id = state.processedItem["id"];
                String data = state.ps;
                List imgdata = state.imgData;
                query = {
                  //??????
                  "variables": {
                    "poorConfirmInv": {"value": false},
                    "trackConfirmInv": {"value": true},
                    "currentTaskDeposit": {"value": true},
                    "CategoryManagent_requestData": {"value": data},
                    "CategoryManagent_imgData": {
                      "value": imgdata,
                    },
                    state.processedItem["id"] + "_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {
                      "value": imgdata,
                    },
                    "grade": {"value": state.rate}
                  },
                  "withVariablesInReturn": true
                };

                // if (state.isUseDate) {
                if (type == "next" || type == "follow") {
                  //????????????
                  // var reslut = state.reslutDate.difference(DateTime.now());
                  // int time = reslut.inMinutes + state.reslutTime;
                  // if (time < 0) {
                  //   //TODO:
                  //   yield state.copyWith(changTextColor: true);
                  //   return;
                  // }
                  String reslutvalue = "";
                  if (type == "next") {
                    reslutvalue = "P" + state.nextDate.toString() + "D";
                  }
                  //TODO:
                  if (type == "follow") {
                    reslutvalue = "PT1S";
                  }

                  print(reslutvalue);
                  query = {
                    "variables": {
                      "reminderTimeInv": {"value": reslutvalue},
                      "trackConfirmInv": {"value": false},
                      "poorConfirmInv": {"value": false},
                      "CategoryManagent_requestData": {"value": data},
                      "CategoryManagent_imgData": {
                        "value": imgdata,
                      },
                      state.processedItem["id"] + "_requestData": {
                        "value": data
                      },
                      state.processedItem["id"] + "_imgData": {
                        "value": imgdata,
                      },
                      "grade": {"value": state.rate}
                    },
                    "withVariablesInReturn": true
                  };
                }

                break;
              case "Activity_0639vrl": // ????????????
                var id = state.processedItem["id"];
                String data = state.ps;
                List imgdata = state.imgData;
                query = {
                  //??????
                  "variables": {
                    "poorConfirmInv": {"value": false},
                    "trackConfirmInv": {"value": true},
                    "currentTaskDeposit": {"value": true},
                    "Activity_0639vrl_requestData": {"value": data},
                    "Activity_0639vrl_imgData": {
                      "value": imgdata,
                    },
                    state.processedItem["id"] + "_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {
                      "value": imgdata,
                    },
                    "grade": {"value": state.rate}
                  },
                  "withVariablesInReturn": true
                };

                // if (state.isUseDate) {
                if (type == "next" || type == "follow") {
                  //????????????
                  // var reslut = state.reslutDate.difference(DateTime.now());
                  // int time = reslut.inMinutes + state.reslutTime;
                  // if (time < 0) {
                  //   //TODO:
                  //   yield state.copyWith(changTextColor: true);
                  //   return;
                  // }
                  String reslutvalue = "";
                  if (type == "next") {
                    reslutvalue = "P" + state.nextDate.toString() + "D";
                  }

                  if (type == "follow") {
                    reslutvalue = "PT1S";
                  }

                  print(reslutvalue);
                  query = {
                    "variables": {
                      "reminderTimeInv": {"value": reslutvalue},
                      "trackConfirmInv": {"value": false},
                      "poorConfirmInv": {"value": false},
                      "Activity_0639vrl_requestData": {"value": data},
                      "Activity_0639vrl_imgData": {
                        "value": imgdata,
                      },
                      state.processedItem["id"] + "_requestData": {
                        "value": data
                      },
                      state.processedItem["id"] + "_imgData": {
                        "value": imgdata,
                      },
                      "grade": {"value": state.rate}
                    },
                    "withVariablesInReturn": true
                  };
                }

                break;
              case "Activity_1h77h4t": //??????????????????
                var id = state.processedItem["id"];
                String data = state.ps;
                List imgdata = state.imgData;
                query = {
                  //??????
                  "variables": {
                    "poorConfirmInv": {"value": false},
                    "trackConfirmInv": {"value": true},
                    "Activity_1h77h4t_requestData": {"value": data},
                    "Activity_1h77h4t_imgData": {
                      "value": imgdata,
                    },
                    state.processedItem["id"] + "_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {
                      "value": imgdata,
                    },
                    // "currentTaskDeposit": {"value": true},
                    "grade": {"value": state.rate}
                  },
                  "withVariablesInReturn": true
                };

                // if (state.isUseDate) {
                if (type == "next" || type == "follow") {
                  //????????????
                  // var reslut = state.reslutDate.difference(DateTime.now());
                  // int time = reslut.inMinutes + state.reslutTime;
                  // if (time < 0) {
                  //   //TODO:
                  //   yield state.copyWith(changTextColor: true);
                  //   return;
                  // }
                  String reslutvalue = "";
                  if (type == "next") {
                    reslutvalue = "P" + state.nextDate.toString() + "D";
                  }

                  if (type == "follow") {
                    reslutvalue = "PT1S";
                  }

                  print(reslutvalue);
                  query = {
                    "variables": {
                      "reminderTimeInv": {"value": reslutvalue},
                      "trackConfirmInv": {"value": false},
                      "poorConfirmInv": {"value": false},
                      "Activity_1h77h4t_requestData": {"value": data},
                      "Activity_1h77h4t_imgData": {
                        "value": imgdata,
                      },
                      state.processedItem["id"] + "_requestData": {
                        "value": data
                      },
                      state.processedItem["id"] + "_imgData": {
                        "value": imgdata,
                      },
                      "grade": {"value": state.rate}
                    },
                    "withVariablesInReturn": true
                  };
                }

                break;
              case "Activity_0qvod3g":
                String data = state.ps;
                List imgdata = state.imgData;

                List endHoustList = state.endListData;
                List endList = [];
                var id = state.processedItem["id"];
                for (var i = 0; i < endHoustList.length; i++) {
                  Map<String, String> obj = {
                    "serialNumber": endHoustList[i]["serialNumber"],
                    "staging": endHoustList[i]["staging"],
                    "building": endHoustList[i]["building"],
                    "entrance": endHoustList[i]["entrance"],
                  };
                  endList.add(obj);
                }

                if (state.processedData["recognition"]["value"] == false) {
                  query = {
                    "variables": {
                      "trackConfirm": {"value": true},
                      "poorConfirm": {"value": false},
                      "houses": {
                        "value": endList,
                        "valueInfo": {
                          "objectTypeName": "java.util.ArrayList",
                          "serializationDataFormat":
                              "application/x-java-serialized-object"
                        }
                      },
                      "Activity_0qvod3g_requestData": {"value": data},
                      "Activity_0qvod3g_imgData": {
                        "value": imgdata,
                      },
                      state.processedItem["id"] + "_requestData": {
                        "value": data
                      },
                      state.processedItem["id"] + "_imgData": {
                        "value": imgdata,
                      },
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  query = {
                    "variables": {
                      "trackConfirm": {"value": true},
                      "poorConfirm": {"value": false},
                      "houses": {
                        "value": [],
                        "valueInfo": {
                          "objectTypeName": "java.util.ArrayList",
                          "serializationDataFormat":
                              "application/x-java-serialized-object"
                        }
                      },
                      "Activity_0qvod3g_requestData": {"value": data},
                      "Activity_0qvod3g_imgData": {
                        "value": imgdata,
                      },
                      state.processedItem["id"] + "_requestData": {
                        "value": data
                      },
                      state.processedItem["id"] + "_imgData": {
                        "value": imgdata,
                      },
                    },
                    "withVariablesInReturn": true
                  };
                }

                // if (state.isUseDate) {
                if (type == "next" || type == "follow") {
                  // var reslut = state.reslutDate.difference(DateTime.now());
                  // int time = reslut.inMinutes + state.reslutTime;
                  // if (time < 0) {
                  //   //TODO:
                  //   yield state.copyWith(changTextColor: true);
                  //   return;
                  // }
                  String reslutvalue = "";
                  if (type == "next") {
                    reslutvalue = "P" + state.nextDate.toString() + "D";
                  }

                  if (type == "follow") {
                    reslutvalue = "PT1S";
                  }
                  query = {
                    "variables": {
                      "reminderTimeDep": {"value": reslutvalue},
                      "trackConfirm": {"value": false},
                      "poorConfirm": {"value": false},
                      "Activity_0qvod3g_requestData": {"value": data},
                      "Activity_0qvod3g_imgData": {
                        "value": imgdata,
                      },
                      state.processedItem["id"] + "_requestData": {
                        "value": data
                      },
                      state.processedItem["id"] + "_imgData": {
                        "value": imgdata,
                      },
                    },
                    "withVariablesInReturn": true
                  };
                }

                break;
              case "Activity_00h6h12": // ?????????????????????
                String data = state.ps;
                List imgdata = state.imgData;
                List endHoustList = state.endListData;
                List endList = [];
                var id = state.processedItem["id"];
                for (var i = 0; i < endHoustList.length; i++) {
                  Map<String, String> obj = {
                    "serialNumber": endHoustList[i]["serialNumber"],
                    "staging": endHoustList[i]["staging"],
                    "building": endHoustList[i]["building"],
                    "entrance": endHoustList[i]["entrance"],
                  };
                  endList.add(obj);
                }
                if (state.processedData["recognition"]["value"] == false) {
                  query = {
                    "variables": {
                      "poorConfirmDep": {"value": false},
                      "trackConfirmDep": {"value": true},
                      "Activity_00h6h12_requestData": {"value": data},
                      "Activity_00h6h12_imgData": {
                        "value": imgdata,
                      },
                      "houses": {
                        "value": endList,
                        "valueInfo": {
                          "objectTypeName": "java.util.ArrayList",
                          "serializationDataFormat":
                              "application/x-java-serialized-object"
                        }
                      },
                      state.processedItem["id"] + "_requestData": {
                        "value": data
                      },
                      state.processedItem["id"] + "_imgData": {
                        "value": imgdata,
                      },
                      "grade": {"value": state.rate}
                    },
                    "withVariablesInReturn": true,
                  };
                } else {
                  query = {
                    "variables": {
                      "poorConfirmDep": {"value": false},
                      "trackConfirmDep": {"value": true},
                      "Activity_00h6h12_requestData": {"value": data},
                      "Activity_00h6h12_imgData": {
                        "value": imgdata,
                      },
                      "houses": {
                        "value": [],
                        "valueInfo": {
                          "objectTypeName": "java.util.ArrayList",
                          "serializationDataFormat":
                              "application/x-java-serialized-object"
                        }
                      },
                      state.processedItem["id"] + "_requestData": {
                        "value": data
                      },
                      state.processedItem["id"] + "_imgData": {
                        "value": imgdata,
                      },
                      "grade": {"value": state.rate}
                    },
                    "withVariablesInReturn": true,
                  };
                }

                // if (state.isUseDate) {
                if (type == "next" || type == "follow") {
                  //????????????

                  String reslutvalue = "";
                  if (type == "next") {
                    reslutvalue = "P" + state.nextDate.toString() + "D";
                  }

                  if (type == "follow") {
                    reslutvalue = "PT1S";
                  }

                  query = {
                    "variables": {
                      "poorConfirmDep": {"value": false},
                      "trackConfirmDep": {"value": false},
                      "reminderTimeDep": {"value": reslutvalue},
                      "Activity_00h6h12_requestData": {"value": data},
                      "Activity_00h6h12_imgData": {
                        "value": imgdata,
                      },
                      state.processedItem["id"] + "_requestData": {
                        "value": data
                      },
                      state.processedItem["id"] + "_imgData": {
                        "value": imgdata,
                      },
                      "grade": {"value": state.rate}
                    },
                    "withVariablesInReturn": true
                  };
                }

                break;
              case "Activity_0vv7s63": //???????????????
                String data = state.ps;
                List imgdata = state.imgData;
                List endHoustList = state.endListData;
                List endList = [];
                var id = state.processedItem["id"];
                for (var i = 0; i < endHoustList.length; i++) {
                  Map<String, String> obj = {
                    "serialNumber": endHoustList[i]["serialNumber"],
                    "staging": endHoustList[i]["staging"],
                    "building": endHoustList[i]["building"],
                    "entrance": endHoustList[i]["entrance"],
                  };
                  endList.add(obj);
                }
                if (state.processedData["recognition"]["value"] == false) {
                  query = {
                    "variables": {
                      "poorConfirmDep": {"value": false},
                      "trackConfirmDep": {"value": true},
                      "Activity_0vv7s63_requestData": {"value": data},
                      "Activity_0vv7s63_imgData": {
                        "value": imgdata,
                      },
                      "houses": {
                        "value": endList,
                        "valueInfo": {
                          "objectTypeName": "java.util.ArrayList",
                          "serializationDataFormat":
                              "application/x-java-serialized-object"
                        }
                      },
                      state.processedItem["id"] + "_requestData": {
                        "value": data
                      },
                      state.processedItem["id"] + "_imgData": {
                        "value": imgdata,
                      },
                      "grade": {"value": state.rate}
                    },
                    "withVariablesInReturn": true,
                  };
                } else {
                  query = {
                    "variables": {
                      "poorConfirmDep": {"value": false},
                      "trackConfirmDep": {"value": true},
                      "Activity_0vv7s63_requestData": {"value": data},
                      "Activity_0vv7s63_imgData": {
                        "value": imgdata,
                      },
                      "houses": {
                        "value": [],
                        "valueInfo": {
                          "objectTypeName": "java.util.ArrayList",
                          "serializationDataFormat":
                              "application/x-java-serialized-object"
                        }
                      },
                      state.processedItem["id"] + "_requestData": {
                        "value": data
                      },
                      state.processedItem["id"] + "_imgData": {
                        "value": imgdata,
                      },
                      "grade": {"value": state.rate}
                    },
                    "withVariablesInReturn": true,
                  };
                }

                // if (state.isUseDate) {
                if (type == "next" || type == "follow") {
                  //????????????

                  String reslutvalue = "";
                  if (type == "next") {
                    reslutvalue = "P" + state.nextDate.toString() + "D";
                  }

                  if (type == "follow") {
                    reslutvalue = "PT1S";
                  }

                  query = {
                    "variables": {
                      "poorConfirmDep": {"value": false},
                      "trackConfirmDep": {"value": false},
                      "reminderTimeDep": {"value": reslutvalue},
                      "Activity_0vv7s63_requestData": {"value": data},
                      "Activity_0vv7s63_imgData": {
                        "value": imgdata,
                      },
                      state.processedItem["id"] + "_requestData": {
                        "value": data
                      },
                      state.processedItem["id"] + "_imgData": {
                        "value": imgdata,
                      },
                      "grade": {"value": state.rate}
                    },
                    "withVariablesInReturn": true
                  };
                }

                break;
              case "Activity_0qk9snp": //???????????????????????????
                String data = state.ps;
                List imgdata = state.imgData;
                var id = state.processedItem["id"];
                List endHoustList = state.endListData;
                List endList = [];

                for (var i = 0; i < endHoustList.length; i++) {
                  Map<String, String> obj = {
                    "serialNumber": endHoustList[i]["serialNumber"],
                    "staging": endHoustList[i]["staging"],
                    "building": endHoustList[i]["building"],
                    "entrance": endHoustList[i]["entrance"],
                  };
                  endList.add(obj);
                }
                if (state.processedData["recognition"]["value"] == false) {
                  query = {
                    "variables": {
                      "poorConfirmDep": {"value": false},
                      "trackConfirmDep": {"value": true},
                      "houses": {
                        "value": endList,
                        "valueInfo": {
                          "objectTypeName": "java.util.ArrayList",
                          "serializationDataFormat":
                              "application/x-java-serialized-object"
                        }
                      },
                      "Activity_0qk9snp_requestData": {"value": data},
                      "Activity_0qk9snp_imgData": {
                        "value": imgdata,
                      },
                      state.processedItem["id"] + "_requestData": {
                        "value": data
                      },
                      state.processedItem["id"] + "_imgData": {
                        "value": imgdata,
                      },
                      "grade": {"value": state.rate}
                    },
                    "withVariablesInReturn": true,
                  };
                } else {
                  query = {
                    "variables": {
                      "poorConfirmDep": {"value": false},
                      "trackConfirmDep": {"value": true},
                      "houses": {
                        "value": [],
                        "valueInfo": {
                          "objectTypeName": "java.util.ArrayList",
                          "serializationDataFormat":
                              "application/x-java-serialized-object"
                        }
                      },
                      "Activity_0qk9snp_requestData": {"value": data},
                      "Activity_0qk9snp_imgData": {
                        "value": imgdata,
                      },
                      state.processedItem["id"] + "_requestData": {
                        "value": data
                      },
                      state.processedItem["id"] + "_imgData": {
                        "value": imgdata,
                      },
                      "grade": {"value": state.rate}
                    },
                    "withVariablesInReturn": true,
                  };
                }
                // query = {
                //   "variables": {
                //     "poorConfirmDep": {"value": false},
                //     "trackConfirmDep": {"value": true},
                //     "Activity_0qk9snp_requestData": {"value": data},
                //     "Activity_0qk9snp_imgData": {
                //       "value": imgdata,
                //     },
                //     state.processedItem["id"] + "_requestData": {"value": data},
                //     state.processedItem["id"] + "_imgData": {
                //       "value": imgdata,
                //     },
                //     "grade": {"value": state.rate}
                //   },
                //   "withVariablesInReturn": true,
                // };
                // if (state.isUseDate) {
                if (type == "next" || type == "follow") {
                  //????????????
                  // var reslut = state.reslutDate.difference(DateTime.now());
                  // print(reslut);
                  // int time = reslut.inMinutes + state.reslutTime;
                  // if (time < 0) {
                  //   //TODO:
                  //   yield state.copyWith(changTextColor: true);
                  //   return;
                  // }
                  String reslutvalue = "";
                  if (type == "next") {
                    reslutvalue = "P" + state.nextDate.toString() + "D";
                  }

                  if (type == "follow") {
                    reslutvalue = "PT1S";
                  }

                  query = {
                    "variables": {
                      "poorConfirmDep": {"value": false},
                      "trackConfirmDep": {"value": false},
                      "reminderTimeDep": {"value": reslutvalue},
                      "grade": {"value": state.rate}
                    },
                    "withVariablesInReturn": true
                  };
                }

                break;
              case "Activity_0fcrae3": //??????

                String data = state.ps;
                List imgdata = state.imgData;
                List endHoustList = state.endListData;
                List endList = [];
                var id = state.processedItem["id"];
                for (var i = 0; i < endHoustList.length; i++) {
                  Map<String, String> obj = {
                    "serialNumber": endHoustList[i]["serialNumber"],
                    "staging": endHoustList[i]["staging"],
                    "building": endHoustList[i]["building"],
                    "entrance": endHoustList[i]["entrance"],
                  };
                  endList.add(obj);
                }

                query = {
                  "variables": {
                    "Activity_0fcrae3_requestData": {"value": data},
                    "Activity_0fcrae3_imgData": {"value": imgdata},
                    "houses": {
                      "value": endList,
                      "valueInfo": {
                        "objectTypeName": "java.util.ArrayList",
                        "serializationDataFormat":
                            "application/x-java-serialized-object"
                      }
                    },
                    state.processedItem["id"] + "_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {"value": imgdata},
                  },
                  "withVariablesInReturn": true
                };
                break;
              case "Activity_1v8yzn1": //????????????

                String data = state.ps;
                List imgdata = state.imgData;
                List endHoustList = state.endListData;
                List endList = [];
                var id = state.processedItem["id"];
                for (var i = 0; i < endHoustList.length; i++) {
                  Map<String, String> obj = {
                    "serialNumber": endHoustList[i]["serialNumber"],
                    "staging": endHoustList[i]["staging"],
                    "building": endHoustList[i]["building"],
                    "entrance": endHoustList[i]["entrance"],
                  };
                  endList.add(obj);
                }

                query = {
                  "variables": {
                    "Activity_1v8yzn1_requestData": {"value": data},
                    "Activity_1v8yzn1_imgData": {"value": imgdata},
                    "houses": {
                      "value": endList,
                      "valueInfo": {
                        "objectTypeName": "java.util.ArrayList",
                        "serializationDataFormat":
                            "application/x-java-serialized-object"
                      }
                    },
                    state.processedItem["id"] + "_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {"value": imgdata},
                  },
                  "withVariablesInReturn": true
                };
                break;
              case "Activity_0ki46oj": //yinghao??????

                String data = state.ps;
                List imgdata = state.imgData;
                List endHoustList = state.endListData;
                List endList = [];
                var id = state.processedItem["id"];
                for (var i = 0; i < endHoustList.length; i++) {
                  Map<String, String> obj = {
                    "serialNumber": endHoustList[i]["serialNumber"],
                    "staging": endHoustList[i]["staging"],
                    "building": endHoustList[i]["building"],
                    "entrance": endHoustList[i]["entrance"],
                  };
                  endList.add(obj);
                }

                query = {
                  "variables": {
                    "Activity_0ki46oj_requestData": {"value": data},
                    "Activity_0ki46oj_imgData": {"value": imgdata},
                    "houses": {
                      "value": endList,
                      "valueInfo": {
                        "objectTypeName": "java.util.ArrayList",
                        "serializationDataFormat":
                            "application/x-java-serialized-object"
                      }
                    },
                    state.processedItem["id"] + "_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {"value": imgdata},
                  },
                  "withVariablesInReturn": true
                };
                break;

              case "Activity_0cy1bz9": // ????????????

                String data = state.ps;
                List imgdata = state.imgData;
                List endHoustList = state.endListData;
                List endList = [];
                var id = state.processedItem["id"];
                for (var i = 0; i < endHoustList.length; i++) {
                  Map<String, String> obj = {
                    "serialNumber": endHoustList[i]["serialNumber"],
                    "staging": endHoustList[i]["staging"],
                    "building": endHoustList[i]["building"],
                    "entrance": endHoustList[i]["entrance"],
                  };
                  endList.add(obj);
                }
                query = {
                  "variables": {
                    "Activity_0cy1bz9_requestData": {"value": data},
                    "Activity_0cy1bz9_imgData": {"value": imgdata},
                    "houses": {
                      "value": endList,
                      "valueInfo": {
                        "objectTypeName": "java.util.ArrayList",
                        "serializationDataFormat":
                            "application/x-java-serialized-object"
                      }
                    },
                    state.processedItem["id"] + "_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {"value": imgdata},
                  },
                  "withVariablesInReturn": true
                };
                break;
              case "Activity_10po9sk": //????????????
                String data = state.ps;
                List imgdata = state.imgData;
                query = {
                  "variables": {
                    "Activity_10po9sk_imgData": {"value": imgdata},
                    "Activity_10po9sk_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {"value": imgdata},
                    state.processedItem["id"] + "_requestData": {"value": data},
                  },
                  "withVariablesInReturn": true
                };
                break;
              case "Activity_0ndvcvv": //??????????????????
                String data = state.ps;
                List imgdata = state.imgData;
                query = {
                  "variables": {
                    "Activity_0ndvcvv_imgData": {"value": imgdata},
                    "Activity_0ndvcvv_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {"value": imgdata},
                    state.processedItem["id"] + "_requestData": {"value": data},
                  },
                  "withVariablesInReturn": true
                };
                break;
              case "Activity_00n2pwo": //????????????
                String data = state.ps;
                List imgdata = state.imgData;
                query = {
                  "variables": {
                    "Activity_00n2pwo_imgData": {"value": imgdata},
                    "Activity_00n2pwo_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {"value": imgdata},
                    state.processedItem["id"] + "_requestData": {"value": data},
                  },
                  "withVariablesInReturn": true
                };
                break;
              case "Activity_1otznpp": // ?????? ????????????
                String data = state.ps;
                List imgdata = state.imgData;
                query = {
                  "variables": {
                    "Activity_1otznpp_imgData": {"value": imgdata},
                    "Activity_1otznpp_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {"value": imgdata},
                    state.processedItem["id"] + "_requestData": {"value": data},
                  },
                  "withVariablesInReturn": true
                };
                break;
              case "Activity_1olkns4": //????????????
                String data = state.ps;
                List imgdata = state.imgData;
                query = {
                  "variables": {
                    "Activity_1olkns4_requestData": {"value": data},
                    "Activity_1olkns4_imgData": {"value": imgdata},
                    state.processedItem["id"] + "_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {"value": imgdata},
                  },
                  "withVariablesInReturn": true
                };
                break;
              case "Activity_1cbo1ao": //??????????????????
                String data = state.ps;
                List imgdata = state.imgData;
                query = {
                  "variables": {
                    "Activity_1cbo1ao_requestData": {"value": data},
                    "Activity_1cbo1ao_imgData": {"value": imgdata},
                    state.processedItem["id"] + "_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {"value": imgdata},
                  },
                  "withVariablesInReturn": true
                };
                break;
              case "Activity_1xgd1ne": // ??????????????????
                String data = state.ps;
                List imgdata = state.imgData;
                query = {
                  "variables": {
                    "Activity_1xgd1ne_requestData": {"value": data},
                    "Activity_1xgd1ne_imgData": {"value": imgdata},
                    state.processedItem["id"] + "_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {"value": imgdata},
                  },
                  "withVariablesInReturn": true
                };
                break;
              case "Activity_0yyexii": //????????????
                String data = state.ps;
                List imgdata = state.imgData;
                query = {
                  "variables": {
                    "Activity_0yyexii_requestData": {"value": data},
                    "Activity_0yyexii_imgData": {"value": imgdata},
                    state.processedItem["id"] + "_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {"value": imgdata},
                  },
                  "withVariablesInReturn": true
                };
                break;
              case "Activity_0ossp3s": //????????????

                query = {
                  "variables": {
                    "fangyuan": {"value": "ai"},
                  },
                  "withVariablesInReturn": true
                };
                break;
            }

            // if (state.rate == "D") {
            if (type == "D") {
              //D???????????????
              String data = state.ps;
              List imgdata = state.imgData;
              if (state.processedItem["taskDefinitionKey"] ==
                  "CategoryManagent") {
                query = {
                  //??????
                  "variables": {
                    "poorConfirmInv": {"value": true},
                    "trackConfirmInv": {"value": false},
                    "InvInvalidConfirmed": {"value": "D"},
                    state.processedItem["id"] + "_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {"value": imgdata},
                  },
                  "withVariablesInReturn": true
                };
              }
              if (state.processedItem["taskDefinitionKey"] ==
                  "Activity_0639vrl") {
                query = {
                  // ????????????
                  "variables": {
                    "poorConfirmInv": {"value": true},
                    "trackConfirmInv": {"value": false},
                    "InvInvalidConfirmed": {"value": "D"},
                    state.processedItem["id"] + "_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {"value": imgdata},
                  },
                  "withVariablesInReturn": true
                };
              }
              if (state.processedItem["taskDefinitionKey"] == //????????????
                  "Activity_1h77h4t") {
                query = {
                  //??????
                  "variables": {
                    "poorConfirmInv": {"value": true},
                    "InvInvalidConfirmed": {"value": "D"},
                    state.processedItem["id"] + "_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {"value": imgdata},
                  },
                  "withVariablesInReturn": true
                };
              }
              if (state.processedItem["taskDefinitionKey"] == //????????????
                  "Activity_0qk9snp") {
                query = {
                  //??????
                  "variables": {
                    "poorConfirmDep": {"value": true},
                    "InvInvalidConfirmed": {"value": "D"},
                    state.processedItem["id"] + "_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {"value": imgdata},
                  },
                  "withVariablesInReturn": true
                };
              }
              if (state.processedItem["taskDefinitionKey"] ==
                  "Activity_00h6h12") {
                //D?????????
                // grade ????????????  ??????
                query = {
                  "variables": {
                    "poorConfirmDep": {"value": true},
                    "trackConfirmDep": {"value": false},
                    "DepInvalidConfirmed": {"value": "D"},
                    state.processedItem["id"] + "_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {"value": imgdata},
                  },
                  "withVariablesInReturn": true
                };
              }
              if (state.processedItem["taskDefinitionKey"] ==
                  "Activity_0vv7s63") {
                //D?????????
                // grade ????????????
                query = {
                  "variables": {
                    "poorConfirmDep": {"value": true},
                    "trackConfirmDep": {"value": false},
                    "DepInvalidConfirmed": {"value": "D"},
                    state.processedItem["id"] + "_requestData": {"value": data},
                    state.processedItem["id"] + "_imgData": {"value": imgdata},
                  },
                  "withVariablesInReturn": true
                };
              }
              var res = await _iMessagesFacade.processSalesman(
                  state.processedItem["id"], query);
              yield state.copyWith(processResult: res);
            } else {
              var res = await _iMessagesFacade.processSalesman(
                  state.processedItem["id"], query);
              yield state.copyWith(processResult: res);
            }
            break;
          case 'manager': //??????
            var query;

            switch (state.processedItem["taskDefinitionKey"]) {
              //????????????
              case "Activity_0fvuxs2":
                if (state.groupValue == 0) {
                  //??????
                  query = {
                    "variables": {
                      "approve": {"value": true}
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  String value = state.ps;
                  query = {
                    //?????????
                    "variables": {
                      "approve": {"value": false},
                      "Activity_0fvuxs2_managerDeration": {"value": value},
                      state.processedItem["id"] + "_managerDeration": {
                        "value": value
                      }
                    },
                    "withVariablesInReturn": true
                  };
                }
                break;
              case "Activity_1f9gn7v":
                if (state.groupValue == 0) {
                  //?????? ??????   ?????????????????????
                  query = {
                    "variables": {
                      "passedDep": {"value": true},
                      // "houses": {
                      //   "value": [],
                      //   "valueInfo": {
                      //     "objectTypeName": "java.util.ArrayList",
                      //     "serializationDataFormat":
                      //         "application/x-java-serialized-object"
                      //   }
                      // },
                      "recognition": {
                        "value": state.processedData["recognition"]["value"]
                      }
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  String value = state.ps;
                  query = {
                    //?????????
                    "variables": {
                      "passedDep": {"value": false},
                      "recognition": {
                        "value": state.processedData["recognition"]["value"]
                      },
                      "Activity_1f9gn7v_managerDeration": {"value": value},
                      state.processedItem["id"] + "_managerDeration": {
                        "value": value
                      }
                    },
                    "withVariablesInReturn": true
                  };
                }
                break;
              case "Activity_1atwvxw":
                if (state.groupValue == 0) {
                  //??????
                  query = {
                    "variables": {
                      "passedDep": {"value": true},
                      "recognition": {
                        "value": state.processedData["recognition"]["value"]
                      }
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  String value = state.ps;
                  query = {
                    //?????????
                    "variables": {
                      "passedDep": {"value": false},
                      "recognition": {
                        "value": state.processedData["recognition"]["value"]
                      },
                      "Activity_1atwvxw_managerDeration": {"value": value},
                      state.processedItem["id"] + "_managerDeration": {
                        "value": value
                      }
                    },
                    "withVariablesInReturn": true
                  };
                }
                break;
              case "Activity_1vkay0h":
                if (state.groupValue == 0) {
                  //??????
                  query = {
                    "variables": {
                      "passedDep": {"value": true},
                      "recognition": {
                        "value": state.processedData["recognition"]["value"]
                      }
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  String value = state.ps;
                  query = {
                    //?????????
                    "variables": {
                      "passedDep": {"value": false},
                      "recognition": {
                        "value": state.processedData["recognition"]["value"]
                      },
                      "Activity_1vkay0h_managerDeration": {"value": value},
                      state.processedItem["id"] + "_managerDeration": {
                        "value": value
                      }
                    },
                    "withVariablesInReturn": true
                  };
                }
                break;
              case "Activity_0x97rbo":
                if (state.groupValue == 0) {
                  //??????
                  query = {
                    "variables": {
                      "passedDep": {"value": true},
                      "recognition": {
                        "value": state.processedData["recognition"]["value"]
                      },
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  String value = state.ps;
                  query = {
                    //?????????
                    "variables": {
                      "passedDep": {"value": false},
                      "recognition": {
                        "value": state.processedData["recognition"]["value"]
                      },
                      "Activity_0x97rbo_managerDeration": {"value": value},
                      state.processedItem["id"] + "_managerDeration": {
                        "value": value
                      }
                    },
                    "withVariablesInReturn": true
                  };
                }
                break;
              case "ManagerAssigns": //????????????
                String id = "";
                // List<dynamic> list = state.salesmanMapList;
                // String name = state.manageAssignmentUser;
                for (int i = 0; i < state.salesmanMapList.length; i++) {
                  if (state.manageAssignmentUser ==
                      state.salesmanMapList[i]["realName"]) {
                    id = state.salesmanMapList[i]["id"];
                  }
                }
                bool isExit =
                    state.processedData.containsKey("currentTaskDeposit");
                if (isExit) {
                  query = {
                    "variables": {
                      "repetition": {"value": true},
                      "agentId": {"value": id},
                      "currentTaskDeposit": {"value": true}
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  query = {
                    "variables": {
                      "repetition": {"value": true},
                      "agentId": {"value": id},
                      "currentTaskDeposit": {"value": false}
                    },
                    "withVariablesInReturn": true
                  };
                }

                break;

              case "Activity_0lpau4d": //????????????
                String id = "";
                // List<dynamic> list = state.salesmanMapList;
                // String name = state.manageAssignmentUser;
                for (int i = 0; i < state.salesmanMapList.length; i++) {
                  if (state.manageAssignmentUser ==
                      state.salesmanMapList[i]["realName"]) {
                    id = state.salesmanMapList[i]["id"];
                  }
                }
                bool isExit =
                    state.processedData.containsKey("currentTaskDeposit") &&
                        state.processedData["currentTaskDeposit"]["value"];
                if (isExit) {
                  query = {
                    "variables": {
                      "repetition": {"value": true},
                      "agentId": {"value": id},
                      "currentTaskDeposit": {"value": true}
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  query = {
                    "variables": {
                      "repetition": {"value": true},
                      "agentId": {"value": id},
                      "currentTaskDeposit": {"value": false}
                    },
                    "withVariablesInReturn": true
                  };
                }

                break;
              case "Activity_1u7ja7r": //????????????
                String id = "";
                // List<dynamic> list = state.salesmanMapList;
                // String name = state.manageAssignmentUser;
                for (int i = 0; i < state.salesmanMapList.length; i++) {
                  if (state.manageAssignmentUser ==
                      state.salesmanMapList[i]["realName"]) {
                    id = state.salesmanMapList[i]["id"];
                  }
                }
                bool isExit =
                    state.processedData.containsKey("currentTaskDeposit");
                if (isExit) {
                  query = {
                    "variables": {
                      "repetition": {"value": true},
                      "agentId": {"value": id},
                      "currentTaskDeposit": {"value": true}
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  query = {
                    "variables": {
                      "repetition": {"value": true},
                      "agentId": {"value": id},
                      "currentTaskDeposit": {"value": false}
                    },
                    "withVariablesInReturn": true
                  };
                }

                break;
              case "Activity_1p4qp4l": //????????????

                String value = state.ps;
                if (state.groupValue == 0) {
                  query = {
                    "variables": {
                      "passedTransfer": {"value": true},
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  query = {
                    "variables": {
                      "passedTransfer": {"value": false},
                      "Activity_1p4qp4l_managerDeration": {"value": value},
                      state.processedItem["id"] + "_managerDeration": {
                        "value": value
                      },
                    },
                    "withVariablesInReturn": true
                  };
                }

                break;
              case "Activity_0k719dd": //??????????????????

                String value = state.ps;
                if (state.groupValue == 0) {
                  query = {
                    "variables": {
                      "passedTransfer": {"value": true},
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  query = {
                    "variables": {
                      "passedTransfer": {"value": false},
                      "Activity_0k719dd_managerDeration": {"value": value},
                      state.processedItem["id"] + "_managerDeration": {
                        "value": value
                      },
                    },
                    "withVariablesInReturn": true
                  };
                }

                break;
              case "Activity_1gaipmg": //yi????????????

                String value = state.ps;
                if (state.groupValue == 0) {
                  query = {
                    "variables": {
                      "passedTransfer": {"value": true},
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  query = {
                    "variables": {
                      "passedTransfer": {"value": false},
                      "Activity_1gaipmg_managerDeration": {"value": value},
                      state.processedItem["id"] + "_managerDeration": {
                        "value": value
                      },
                    },
                    "withVariablesInReturn": true
                  };
                }

                break;
              case "Activity_0zeqsng": //??????????????????

                String value = state.ps;
                if (state.groupValue == 0) {
                  query = {
                    "variables": {
                      "passedTransfer": {"value": true},
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  query = {
                    "variables": {
                      "passedTransfer": {"value": false},
                      "Activity_0zeqsng_managerDeration": {"value": value},
                      state.processedItem["id"] + "_managerDeration": {
                        "value": value
                      },
                    },
                    "withVariablesInReturn": true
                  };
                }

                break;

              case "Activity_0ar3k0c": //????????????
                String value = state.ps;
                if (state.groupValue == 0) {
                  query = {
                    "variables": {
                      "passedContract": {"value": true}, //????????????????????????
                      "skipLoan": {
                        "value": state.processedData["skipLoan"]["value"]
                      },
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  query = {
                    "variables": {
                      "passedContract": {"value": false},
                      "Activity_0ar3k0c_managerDeration": {"value": value},
                      state.processedItem["id"] + "_managerDeration": {
                        "value": value
                      }
                    },
                    "withVariablesInReturn": true
                  };
                }
                break;
              case "Activity_1o336vo": //??????????????????
                String value = state.ps;
                if (state.groupValue == 0) {
                  query = {
                    "variables": {
                      "passedContract": {"value": true}, //????????????????????????
                      "skipLoan": {
                        "value": state.processedData["skipLoan"]["value"]
                      },
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  query = {
                    "variables": {
                      "passedContract": {"value": false},
                      "Activity_1o336vo_managerDeration": {"value": value},
                      state.processedItem["id"] + "_managerDeration": {
                        "value": value
                      }
                    },
                    "withVariablesInReturn": true
                  };
                }
                break;
              case "Activity_0kdzv8w": //??????????????????
                String value = state.ps;
                if (state.groupValue == 0) {
                  query = {
                    "variables": {
                      "passedContract": {"value": true} //????????????????????????
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  query = {
                    "variables": {
                      "passedContract": {"value": false},
                      "Activity_0kdzv8w_managerDeration": {"value": value},
                      state.processedItem["id"] + "_managerDeration": {
                        "value": value
                      }
                    },
                    "withVariablesInReturn": true
                  };
                }
                break;
              case "Activity_0lnm3vn": //??????????????????
                String value = state.ps;
                if (state.groupValue == 0) {
                  query = {
                    "variables": {
                      "passedContract": {"value": true}, //????????????????????????
                      "skipLoan": {
                        "value": state.processedData["skipLoan"]["value"]
                      },
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  query = {
                    "variables": {
                      "passedContract": {"value": false},
                      "Activity_0lnm3vn_managerDeration": {"value": value},
                      state.processedItem["id"] + "_managerDeration": {
                        "value": value
                      }
                    },
                    "withVariablesInReturn": true
                  };
                }
                break;
              case "Activity_0sjwc2q": //??????????????????
                String value = state.ps;
                if (state.groupValue == 0) {
                  query = {
                    "variables": {
                      "passedLoan": {"value": true} //??????????????????
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  query = {
                    "variables": {
                      "passedLoan": {"value": false}, //??????????????????
                      "Activity_0sjwc2q_managerDeration": {"value": value},
                      state.processedItem["id"] + "_managerDeration": {
                        "value": value
                      }
                    },
                    "withVariablesInReturn": true
                  };
                }

                break;
              case "Activity_19m52i0": //??????????????????
                String value = state.ps;
                if (state.groupValue == 0) {
                  query = {
                    "variables": {
                      "passedLoan": {"value": true} //??????????????????
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  query = {
                    "variables": {
                      "passedLoan": {"value": false}, //??????????????????
                      "Activity_19m52i0_managerDeration": {"value": value},
                      state.processedItem["id"] + "_managerDeration": {
                        "value": value
                      }
                    },
                    "withVariablesInReturn": true
                  };
                }
                break;
              case "Activity_0tkddk1": //??????????????????
                String value = state.ps;
                if (state.groupValue == 0) {
                  query = {
                    "variables": {
                      "passedLoan": {"value": true} //??????????????????
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  query = {
                    "variables": {
                      "passedLoan": {"value": false}, //??????????????????
                      "Activity_0tkddk1_managerDeration": {"value": value},
                      state.processedItem["id"] + "_managerDeration": {
                        "value": value
                      }
                    },
                    "withVariablesInReturn": true
                  };
                }
                break;
              case "FreezeAudit": //????????????
                String value = state.ps;
                if (state.groupValue == 0) {
                  query = {
                    "variables": {
                      "passedFreeze": {"value": true},
                      "suspendTask": {"value": false}
                    },
                    "withVariablesInReturn": true
                  };
                } else {
                  query = {
                    "variables": {
                      "passedFreeze": {"value": false},
                      "suspendTask": {"value": false},
                      "freezeAudit_managerDeration": {"value": value},
                      state.processedItem["id"] + "_managerDeration": {
                        "value": value
                      },
                    },
                    "withVariablesInReturn": true
                  };
                }
                break;
            }
            // if (state.processedItem["taskDefinitionKey"] ==
            //     "Activity_1atwvxw") {
            //   if (state.groupValue == 0) {
            //     query = {
            //       "variables": {
            //         "passedDep": {"value": true},
            //         "recognition": {"value": true}
            //       }
            //     };
            //   } else {
            //     query = {
            //       "variables": {
            //         "passedDep": {"value": false},
            //       }
            //     };
            //   }
            // } else {
            //   query = {
            //     "variables": {
            //       "agentId": {"value": "1332158148605116417"},
            //     }
            //   };
            // }

            var res = await _iMessagesFacade.processSalesman(
                state.processedItem["id"], query);
            yield state.copyWith(processResult: res);
            break;
          case 'financial': //??????
            String data = state.ps;
            List imgdata = state.imgData;
            Map<String, dynamic> query;
            query = {
              "variables": {
                "settlement": {"value": true}, //??????
                "Activity_07a78ln_requestData": {"value": data},
                "Activity_07a78ln_imgData": {"value": imgdata},
                state.processedItem["id"] + "_requestData": {"value": data},
                state.processedItem["id"] + "_imgData": {"value": imgdata},
              },
              "withVariablesInReturn": true
            };
            var res = await _iMessagesFacade.processSalesman(
                state.processedItem["id"], query);
            yield state.copyWith(processResult: res);
            break;

          case 'director': //??????
            var query;
            if (state.processedItem["taskDefinitionKey"] ==
                "Activity_0fvuxs2") {
              if (state.groupValue == 0) {
                //??????
                query = {
                  "variables": {
                    "approve": {"value": true}
                  },
                  "withVariablesInReturn": true
                };
              } else {
                String value = state.ps;
                query = {
                  //?????????
                  "variables": {
                    "approve": {"value": false},
                    "Activity_0fvuxs2_managerDeration": {"value": value},
                    state.processedItem["id"] + "_managerDeration": {
                      "value": value
                    }
                  },
                  "withVariablesInReturn": true
                };
              }
            }
            var res = await _iMessagesFacade.processSalesman(
                state.processedItem["id"], query);
            yield state.copyWith(processResult: res);
            break;
        }
      },
      changeRadio: (value) async* {
        yield state.copyWith(groupValue: value.value);
      },
      getSalesmanList: (value) async* {
        var res = await _iMessagesFacade.getSalesmanList(value.affId);
        List manageAssignmentUserData = [];

        yield state.copyWith(salesmanList: res);
      },
      saveManageAssignmentUser: (value) async* {
        yield state.copyWith(manageAssignmentUser: value.manageAssignmentUser);
        // var item = state.salesmanList.forEach((element) {
        //   if (element["name"] == value.manageAssignmentUser) {
        //     return element;
        //   } else {
        //     return null;
        //   }
        // });
        // Map<String, dynamic> query = {
        //   "agentId": {"value": ""},
        // };
        // var res = await _iMessagesFacade.processSalesman(
        //     state.processedItem["id"], query);
        // yield state.copWith();
      },
      changeNextTime: (value) async* {
        yield state.copyWith(nextTime: value.value);
      },
      getNextTimeData: (value) async* {
        if (state.processedItem["taskDefinitionKey"] == "CategoryManagent" ||
            state.processedItem["taskDefinitionKey"] == "Activity_0vv7s63" ||
            state.processedItem["taskDefinitionKey"] == "Activity_0qvod3g" ||
            state.processedItem["taskDefinitionKey"] == "Activity_1h77h4t" ||
            state.processedItem["taskDefinitionKey"] == "Activity_0qk9snp" ||
            state.processedItem["taskDefinitionKey"] == "Activity_0639vrl" ||
            state.processedItem["taskDefinitionKey"] == "Activity_00h6h12") {
          var res = await _iMessagesFacade
              .getNextTimeData(state.processedItem["processInstanceId"]);
          //  res = res[0];
          print(res);
          var dateList = [];
          // if (res[0]["processDefinitionKey"] == "enrecommend") {
          if (state.processedItem["taskDefinitionKey"] == "Activity_0qvod3g") {
            var iisdate = DateTime.parse(res[0]["dueDate"]).toLocal();
            print(iisdate);
            var datetimes = iisdate.difference(new DateTime.now());

            for (var i = 1; i <= datetimes.inDays; i++) {
              dateList.add('${i}???');
            }
            yield state.copyWith(
              enrecommendDate: iisdate,
              dateList: dateList,
            );
            return;
          }
          if (state.processedItem["taskDefinitionKey"] == "CategoryManagent" ||
              state.processedItem["taskDefinitionKey"] == "Activity_0vv7s63") {
            res.sort((a, b) => DateTime.parse(a["dueDate"])
                .toLocal()
                .millisecondsSinceEpoch
                .compareTo(DateTime.parse(b["dueDate"])
                    .toLocal()
                    .millisecondsSinceEpoch));
            print(res);
            print(new DateTime.now().millisecondsSinceEpoch);
            Map<String, dynamic> dateTime = {
              "executionTime": res[0]["dueDate"],
              "validityTime": res[1]["dueDate"],
              "processedTime": res[2]["dueDate"],
            };
            // yield state.copyWith(nextTimeData: dateTime);
            var vTime = DateTime.parse(dateTime["validityTime"]).toLocal();
            var nTime = new DateTime.now(); //????????????
            var diffrence = vTime.difference(nTime); // ??????????????????????????????
            print([
              diffrence.inDays,
              diffrence.inHours,
              diffrence.inMinutes,
              diffrence.inMicroseconds,
              diffrence.inMilliseconds
            ]);
            int diffr = diffrence.inMinutes; //?????????????????????

            String timeString =
                state.processedData["executionDuration"]["value"]; //??????????????????PT15M
            String timestr = timeString.substring(2);
            String timeendstr = timestr.substring(timestr.length - 1);
            var stringTime = timeString.replaceAll(RegExp("[a-zA-Z]"), "");
            int ss;
            int day; //????????????????????????
            switch (timeendstr) {
              case "M": //??????
                ss = int.parse(stringTime);
                break;
              case "H": //??????
                ss = int.parse(stringTime) * 60;
                break;
              case "D": //???
                ss = int.parse(stringTime) * 24 * 60;
                break;
            }
            if (diffr >= ss) {
              day = ss;
            } else {
              day = diffr;
            }
            if (day < 1) {
              return;
            }

            print(day);
            int aaa = int.parse((day / (60 * 24))
                .toString()
                .substring(0, (day / (60 * 24)).toString().indexOf(".")));

            int bbb = int.parse(((day - (aaa * 24 * 60)) / 60)
                .toString()
                .substring(0,
                    (((day - (aaa * 24 * 60))) / 60).toString().indexOf(".")));

            int ccc = day - (aaa * 24 * 60) - (bbb * 60);

            Map<String, dynamic> endTime = {
              "Day": aaa,
              "Hours": bbb,
              "Microseconds": ccc,
            };

            print(endTime);

            // var d6 = new DateTime(2019, 6, 9, 16, 30);
            // var d7 = new DateTime(2019, 6, 29, 16, 30);
            // var difference = d7.difference(d6);
            // print([difference.inDays, difference.inHours, difference.inMinutes]);
            // int a = 123456789123456789;
            // print(a);
            int aaaa = (day / (24 * 60)).floor();
            for (var i = 1; i <= aaaa; i++) {
              dateList.add('${i}???');
            }
            yield state.copyWith(
              nextTimeData: dateTime,
              nextEndTime: endTime, // ??????????????????????????? ???????????????
              microseconds: day, // ????????????  ??????
              dateList: dateList,
            );
          }
          if (state.processedItem["taskDefinitionKey"] == "Activity_1h77h4t" ||
              state.processedItem["taskDefinitionKey"] == "Activity_0qk9snp") {
            var dateList = [];
            for (var i = 1; i <= 30; i++) {
              dateList.add("${i}???");
            }
            yield state.copyWith(
              // nextTimeData: dateTime,
              // nextEndTime: endTime, // ??????????????????????????? ???????????????
              // microseconds: day, // ????????????  ??????
              dateList: dateList,
            );
          }

          if (state.processedItem["taskDefinitionKey"] == "Activity_0639vrl" ||
              state.processedItem["taskDefinitionKey"] == "Activity_00h6h12") {
            var res = await _iMessagesFacade
                .getNextTimeData(state.processedItem["processInstanceId"]);
            //  res = res[0];
            var iisdate = DateTime.parse(res[0]["dueDate"]).toLocal();
            print(iisdate);
            var datetimes = iisdate.difference(new DateTime.now());
            print(res);
            var dateList = [];
            for (var i = 1; i <= datetimes.inDays; i++) {
              dateList.add("${i}???");
            }
            yield state.copyWith(
              // nextTimeData: dateTime,
              // nextEndTime: endTime, // ??????????????????????????? ???????????????
              // microseconds: day, // ????????????  ??????
              dateList: dateList,
            );
          }

          // print(DateTime.parse("2020-12-08T13:10:34.000+0800")
          //     .toLocal()
          //     .millisecondsSinceEpoch);

        }
      },
      saveDateAndTime: (value) async* {
        DateTime now = DateTime.now();
        DateTime endDate = value.resultDate;
        print(endDate.difference(now));
        int time = 0;
        print(value.resultDate.toString().substring(0, 11));
        if (state.processedItem["taskDefinitionKey"] == "Activity_0qvod3g") {
          var reslut = state.enrecommendDate.difference(endDate);
          print(reslut);
          time = reslut.inMinutes - value.oneDayTimeMine;
        } else if (state.processedItem["taskDefinitionKey"] ==
            "Activity_1h77h4t") {
          var reslut = endDate.difference(DateTime.now());
          print(reslut);
          time = reslut.inMinutes + value.oneDayTimeMine;
        } else {
          var reslut = endDate.difference(DateTime.now());
          print(reslut);
          time = reslut.inMinutes + value.oneDayTimeMine;
        }

        // if (time < 0) {
        //   //TODO:
        //   yield state.copyWith(changTextColor: true);
        // }
        yield state.copyWith(
            changTextColor: time <= 0 ? true : false,
            showStringDate: value.resultDate.toString().substring(0, 11),
            isUseDate: true,
            reslutDate: endDate,
            reslutTime: value.oneDayTimeMine);
      },
      saveRate: (value) async* {
        print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
        print(value.rate);
        if (value.rate == "??????") {
          yield state.copyWith(rate: "");
        } else {
          yield state.copyWith(rate: value.rate);
        }
      },
      savePS: (value) async* {
        yield state.copyWith(ps: value.ps);
      },
      qiNiuLoad: (value) async* {
        String img = value.imgPath;
        var imageName = img.substring(img.lastIndexOf("/") + 1, img.length);
        //  final Directory _temp = await getTemporaryDirectory();
        // final String _path = _temp.path;

        FormData formdataUpload = FormData.fromMap({
          "file": await MultipartFile.fromFile(img, filename: imageName),
          "dir": 'material',
          "fileType": 'image',
          "tenantId": state.processedData["tenantId"]["value"],
        });

        var res = await _iMessagesFacade.qiNiuLoad(formdataUpload);
        var reulst = jsonDecode(res);
        print(res);
        print(reulst);
        print(reulst["link"]);
        List<dynamic> imgDatas = state.imgData;
        imgDatas.add(reulst["link"]);
        state.copyWith(imgData: imgDatas);
      },
      saveZDValue: (value) async* {
        yield state.copyWith(zDValue: value.zDValue);
      },
      removeImg: (value) async* {
        int index = value.index;
        List data = state.imgData;
        data.remove(index);

        yield state.copyWith(imgData: data);
      },
      frezzeCoumer: (value) async* {
        String inputValue = value.inputValue;
        Map<String, dynamic> query = {
          "value": "true",
          "type": "Boolean",
          "frozenReasons": {"value": inputValue},
          "suspendTask": "true"
        };
        var res = await _iMessagesFacade.frezzeprcessed(
            state.processedItem["processInstanceId"], query);
      },
      unFrezzeCoumer: (value) async* {
        Map<String, dynamic> query = {
          "suspended": false
          // "frozenReasons": {"value": inputValue},
          // "suspendTask": "true"
        };
        var res = await _iMessagesFacade.unFrezzeprcessed(
            state.processedItem["processInstanceId"], query);
      },
      isPressed: (value) async* {
        yield state.copyWith(isprocess: !state.isprocess);
      },
      updateRemarks: (e) async* {
        Map<String, dynamic> data = {
          "id": e.id,
          "name": e.name,
        };
        var response = await _iHouseFacade.updateRemarks(data);
        print(response);
      },
      getHouseList: (value) async* {
        var it = state;
        Map<String, dynamic> query = {
          "affiliationId": state.processedData["affiliationId"]["value"],
          "tenantId": state.processedData["tenantId"]["value"],
        };
        var res = await _iMessagesFacade.getHouseList(query);
        print(res);
        yield state.copyWith(stagingList: res['data']);
        // Map<String, dynamic> queryList = {
        //   "staging": res['data'][0],
        //   "building": "",
        //   "entrance": "",
        //   "affiliationId": state.processedData["affiliationId"]["value"],
        //   "tenantId": state.processedData["tenantId"]["value"],
        // };
        // var ress = await _iMessagesFacade.getHouseListData(queryList);
        // print(ress);
      },
      saveNextDate: (value) async* {
        String nextDate = value.date;
        if (nextDate == "0") {
          yield state.copyWith(
            nextDate: "",
            isUseDate: false,
          );
        } else {
          var stringTime = nextDate.replaceAll(RegExp("[^0-9]"), "");
          print(nextDate);
          print(stringTime);
          yield state.copyWith(
            nextDate: stringTime,
            isUseDate: true,
          );
        }
      },
      saveHouseData: (value) async* {
        print(value);
        switch (value.type) {
          case 'Q':
            yield state.copyWith(
              staging: value.data,
              building: "??????",
              entrance: "??????",
              room: "?????????",
            );
            break;
          case 'D':
            yield state.copyWith(
              building: value.data,
              entrance: "??????",
              room: "?????????",
            );
            break;
          case 'C':
            yield state.copyWith(
              entrance: value.data,
              room: "?????????",
            );
            break;
          case 'F':
            // String content = value.data["state"];
            yield state.copyWith(
                room: value.data["serialNumber"], roomMap: value.data);
            break;
          default:
        }
      },
      saveHouseChoose: (value) async* {
        List<dynamic> list = state.chooseHouse;
        String data =
            state.staging + state.building + state.entrance + state.room;
        list.add(data);
        print(state.roomMap);
        List endListData = state.endListData;
        endListData.add(state.roomMap);
        yield state.copyWith(
          chooseHouse: list,
          staging: "??????",
          building: "??????",
          entrance: "??????",
          room: "?????????",
          endListData: endListData,
        );
      },
      checkHouse: (value) async* {
        List<dynamic> checkRes = [];
        if (state.processedData.containsKey("houses") &&
            state.processedData["houses"]["value"].length != 0) {
          List list = state.processedData["houses"]["value"];
          for (var i = 0; i < list.length; i++) {
            Map<String, dynamic> queryList = {
              "staging": list[i]["staging"],
              "building": list[i]["building"],
              "entrance": list[i]["entrance"],
              "affiliationId": state.processedData["affiliationId"]["value"],
              "tenantId": state.processedData["tenantId"]["value"],
            };
            var ress = await _iMessagesFacade.getHouseListData(queryList);
            print(ress);
            List housingList = ress["data"]["housingList"];
            for (var j = 0; j < housingList.length; j++) {
              if (housingList[j]["serialNumber"] == list[i]["serialNumber"] &&
                  housingList[j]["staging"] == list[i]["staging"] &&
                  housingList[j]["building"] == list[i]["building"] &&
                  housingList[j]["entrance"] == list[i]["entrance"]) {
                if (housingList[j]["state"] != "0") {
                  checkRes.add(list[i]);
                }
              }
            }
          }

          yield state.copyWith(checkRes: checkRes);
        }
        if (state.processedData.containsKey("houseInfo") &&
            state.processedData["houseInfo"]["value"] != null) {
          Map<String, dynamic> houseInfo =
              state.processedData["houseInfo"]["value"];
          Map<String, dynamic> queryList = {
            "staging": houseInfo["staging"],
            "building": houseInfo["building"],
            "entrance": houseInfo["entrance"],
            "affiliationId": state.processedData["affiliationId"]["value"],
            "tenantId": state.processedData["tenantId"]["value"],
          };
          var ress = await _iMessagesFacade.getHouseListData(queryList);
          print(ress);
          List housingList = ress["data"]["housingList"];
          for (var j = 0; j < housingList.length; j++) {
            if (housingList[j]["serialNumber"] == houseInfo["serialNumber"] &&
                housingList[j]["staging"] == houseInfo["staging"] &&
                housingList[j]["building"] == houseInfo["building"] &&
                housingList[j]["entrance"] == houseInfo["entrance"]) {
              if (housingList[j]["state"] != "0") {
                checkRes.add(houseInfo);
              }
            }
          }
          yield state.copyWith(checkRes: checkRes);
        }
      },
      getHouseListData: (value) async* {
        Map<String, dynamic> queryList = {
          "staging": state.staging == "??????" ? "" : state.staging,
          "building": state.building == "??????" ? "" : state.building,
          "entrance": state.entrance == "??????" ? "" : state.entrance,
          "affiliationId": state.processedData["affiliationId"]["value"],
          "tenantId": state.processedData["tenantId"]["value"],
        };
        var ress = await _iMessagesFacade.getHouseListData(queryList);
        print(ress);
        List list = ress['data']['housingList'];
        List listss = [];
        for (var i = 0; i < list.length; i++) {
          if (list[i]['state'] == "0") {
            listss.add(list[i]);
          }
        }
        yield state.copyWith(
          buildingList: ress['data']['buildingList'],
          entranceList: ress['data']['entranceList'],
          roomList: listss,
        );
      },
      changefollowState: (value) async* {
        yield state.copyWith(followState: !state.followState);
      },
      getRate: (value) async* {
        Map<String, dynamic> query = {
          "current": 1,
          "size": 5,
          "tenantId": state.processedData["tenantId"]["value"],
          "phone": state.processedData["phone"]["value"],
          "workflowStatus": '0',
          "customerName": state.processedData["customerName"]["value"],
        };
        var list = await _coustomerFacade.getCoustomerList(query);
        // print(list["data"]["records"]);
        yield state.copyWith(rateList: list["data"]["records"]);
      },
    );
  }
}
