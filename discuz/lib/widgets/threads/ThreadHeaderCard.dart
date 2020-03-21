import 'package:discuzq/router/route.dart';
import 'package:discuzq/views/users/usersHomeDelegate.dart';
import 'package:flutter/material.dart';

import 'package:discuzq/widgets/common/discuzAvatar.dart';
import 'package:discuzq/models/threadModel.dart';
import 'package:discuzq/models/userModel.dart';
import 'package:discuzq/widgets/common/discuzText.dart';
import 'package:discuzq/ui/ui.dart';

///
/// ThreadHeaderCard
/// 主题的顶部信息显示
class ThreadHeaderCard extends StatelessWidget {
  ///
  /// 作者
  final UserModel author;

  ///
  /// 主题
  final ThreadModel thread;

  const ThreadHeaderCard({@required this.author, @required this.thread});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: <Widget>[
          ///
          /// user avatar
          GestureDetector(
            onTap: () => DiscuzRoute.open(
                context: context,
                widget: UserHomeDelegate(
                  user: author,
                )),
            child: DiscuzAvatar(
              size: 35,
              url: author.avatarUrl,
            ),
          ),

          /// userinfo
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  DiscuzText(author.username),
                  DiscuzText(
                    thread.attributes.createdAt,
                    color: DiscuzApp.themeOf(context).greyTextColor,
                    fontSize: DiscuzApp.themeOf(context).smallTextSize,
                  )
                ],
              ),

              /// pop menu
            ),
          )
        ],
      ),
    );
  }
}