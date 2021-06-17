import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ui/application/messages/processed/processed_bloc.dart';

class ChooseSecView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProcessedBloc, ProcessedState>(
        builder: (context, state) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text("号码有效"),
          Radio(
              value: 0,
              groupValue: state.groupValue,
              onChanged: (value) {
                BlocProvider.of<ProcessedBloc>(context)
                    .add(ProcessedEvent.changeRadio(value));
              }),
          SizedBox(
            width: 50,
          ),
          Text("号码无效"),
          Radio(
              value: 1,
              groupValue: state.groupValue,
              onChanged: (value) {
                BlocProvider.of<ProcessedBloc>(context)
                  ..add(ProcessedEvent.changeRadio(value));
              }),
        ],
      );
    });
  }
}
