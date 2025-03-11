import 'package:flutter/material.dart';

Widget dividerBuilder(divColor) => Expanded(
      child: Divider(
        thickness: 1,
        indent: 13,
        endIndent: 13,
        color: divColor,
      ),
    );
