import 'package:dio/dio.dart';
import 'package:discuzq/models/userFollowModel.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'package:discuzq/states/scopedState.dart';
import 'package:discuzq/states/appState.dart';
import 'package:discuzq/ui/ui.dart';
import 'package:discuzq/widgets/search/searchAppbar.dart';
import 'package:discuzq/utils/StringHelper.dart';
import 'package:discuzq/utils/request/request.dart';
import 'package:discuzq/utils/request/urls.dart';
import 'package:discuzq/widgets/common/discuzToast.dart';
import 'package:discuzq/models/metaModel.dart';
import 'package:discuzq/utils/global.dart';
import 'package:discuzq/utils/request/requestIncluedes.dart';
import 'package:discuzq/models/userModel.dart';
import 'package:discuzq/widgets/common/discuzNomoreData.dart';
import 'package:discuzq/widgets/common/discuzRefresh.dart';
import 'package:discuzq/widgets/skeleton/discuzSkeleton.dart';
import 'package:discuzq/widgets/users/userFollowListTile.dart';

class FollowerListDelegate extends StatefulWidget {
  ///
  /// isToUser
  /// 是否查询关注用户数据
  /// 如果查询我关注的用户 isToUser == false 则查询粉丝用户数据即 fromUser
  /// 默认是true,即查询关注用户的数据
  final bool isToUser;

  const FollowerListDelegate({Key key, this.isToUser = true}) : super(key: key);
  @override
  _FollowerListDelegateState createState() => _FollowerListDelegateState();
}

class _FollowerListDelegateState extends State<FollowerListDelegate> {
  ///
  /// _controller refresh
  ///
  final RefreshController _controller = RefreshController();

  ///
  /// states
  String _username = '';

  ///
  /// _pageNumber
  int _pageNumber = 1;

  ///
  /// loading
  /// 是否正在加载
  bool _loading = false;

  ///
  /// _enablePullUp
  /// 是否允许加载更多
  bool _enablePullUp = false;

  ///
  /// meta
  MetaModel _meta;

  ///
  /// _continueToRead
  /// 是否是连续加载
  bool _continueToRead = false;

  List<UserModel> _users = [];
  List<UserFollowModel> _userFollows = [];

  @override
  void setState(fn) {
    if (!mounted) {
      return;
    }
    super.setState(fn);
  }

  @override
  void initState() {
    super.initState();

    ///
    /// 加载数据
    ///
    Future.delayed(Duration(milliseconds: 450))
        .then((_) async => await _requestData(pageNumber: 1));
  }

  @override
  void dispose() {
    _controller.dispose();
    _users.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScopedStateModelDescendant<AppState>(
      rebuildOnChange: false,
      builder: (context, child, state) => Scaffold(
            appBar: SearchAppbar(
              placeholder: '输入要查找的用户名',
              onSubmit: (String username, bool shouldShowNoticeEmpty) async {
                if (shouldShowNoticeEmpty &&
                    StringHelper.isEmpty(string: username)) {
                  DiscuzToast.failed(context: context, message: '请输入用户名');
                  return;
                }
                setState(() {
                  _username = username;
                });
                await _requestData(context: context, pageNumber: 1);
              },
            ),
            backgroundColor: DiscuzApp.themeOf(context).scaffoldBackgroundColor,
            body: _body(context: context, state: state),
          ));

  /// build body
  Widget _body({@required BuildContext context, @required AppState state}) =>
      DiscuzRefresh(
        enablePullDown: true,
        enablePullUp: _enablePullUp,

        /// 允许乡下加载
        // header: WaterDropHeader(),
        controller: _controller,
        onRefresh: () async {
          await _requestData(pageNumber: 1);
          _controller.refreshCompleted();
        },
        onLoading: () async {
          if (_loading) {
            return;
          }
          await _requestData(pageNumber: _pageNumber + 1);
          _controller.loadComplete();
        },
        child: _buildUsersList(state: state),
      );

  ///
  /// 渲染查找到的用户列表
  Widget _buildUsersList({AppState state}) {
    ///
    /// 骨架屏仅在初始化时加载
    ///
    if (!_continueToRead && _loading) {
      return const DiscuzSkeleton(
        isCircularImage: false,
        length: Global.requestPageLimit,
        isBottomLinesActive: false,
      );
    }

    if (_users.length == 0) {
      return const DiscuzNoMoreData();
    }

    return ListView(
      children: _userFollows.map((UserFollowModel u) {
        ///
        /// 取出UserFollowModel关联的用户
        final dynamic findRelatedUser =
            widget.isToUser ? u.relationships.toUser : u.relationships.fromUser;
        final int findRelatedUserID =
            int.parse(findRelatedUser['data']['id'].toString());

        /// 从数组中取出关联的用户
        final List<UserModel> user =
            _users.where((UserModel el) => el.id == findRelatedUserID).toList();

        if (user == null || user.length == 0) {
          return const SizedBox();
        }

        return UserFollowListTile(
          user: user.first,
          userFollow: u,
          isToUser: widget.isToUser,
        );
      }).toList(),
    );
  }

  ///
  /// 是否允许加载更多页面
  ///
  void _refreshEnablePullUp() {
    final bool enabled =
        _meta == null ? false : _meta.pageCount > _pageNumber ? true : false;
    _enablePullUp = enabled;
  }

  ///
  /// 查找关注我的用户
  Future<void> _requestData({BuildContext context, int pageNumber}) async {
    ///
    /// 如果是第一页的时候要先清空数据，防止数据重复
    if (pageNumber == 1) {
      _users.clear();
    }

    setState(() {
      _loading = true;
    });

    List<String> includes = [
      widget.isToUser ? RequestIncludes.toUser : RequestIncludes.fromUser,
    ];

    final dynamic data = {
      "filter[type]": widget.isToUser ? 1 : 2,
      "page[limit]": Global.requestPageLimit,
      "page[number]": _pageNumber,
      "filter[username]": _username,
      "include": RequestIncludes.toGetRequestQueries(includes: includes),
    };

    Response resp = await Request(context: context)
        .getUrl(url: Urls.follow, queryParameters: data);

    final List<dynamic> usersData = resp.data['included'] ?? [];
    final List<dynamic> userFollowsData = resp.data['data'] ?? [];

    try {
      _users = usersData
          .where((u) => u['type'] == 'users')
          .map((p) => UserModel.fromMap(maps: p['attributes']))
          .toList();
      _userFollows = userFollowsData
          .where((uf) => uf['type'] == 'user_follow')
          .map((p) => UserFollowModel.fromMap(maps: p))
          .toList();
    } catch (e) {
      print(e);
    }

    setState(() {
      _loading = false;
      _pageNumber = pageNumber == null ? _pageNumber + 1 : pageNumber; /// pageNumber 在onload传入时已经自动加1
      _meta = MetaModel.fromMap(maps: resp.data['meta']);
      _refreshEnablePullUp();
    });
  }
}
