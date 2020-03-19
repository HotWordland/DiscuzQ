import 'package:flutter/material.dart';

import 'package:discuzq/widgets/common/discuzText.dart';

///
/// 金融数字
///
class DiscuzAmount extends StatelessWidget {
  final dynamic amount;
  final double textScaleFactor;
  final FontWeight fontWeight;

  const DiscuzAmount(
      {this.amount,
      this.textScaleFactor = 1.4,
      this.fontWeight = FontWeight.bold});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        DiscuzText(
          amount == null ? 0 : amount.toString(),
          fontFamily: 'Roboto Condensed',
          fontWeight: fontWeight,
          color: Colors.white,
          textScaleFactor: textScaleFactor,
        ),
        const SizedBox(width: 5),
        DiscuzText(
          "¥",
          fontFamily: 'Roboto Condensed',
          fontWeight: fontWeight,
          color: Colors.white.withOpacity(.78),
          textScaleFactor: textScaleFactor / 2,
        ),
      ],
    );
  }
}
