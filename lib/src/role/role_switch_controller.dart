import 'package:flutter/widgets.dart';


abstract class RoleSwitchController extends ChangeNotifier {

  bool get canChangeRole;
  void open(BuildContext context);
}
