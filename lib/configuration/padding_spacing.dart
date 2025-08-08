import 'package:flutter/material.dart';

class Spacing {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;

  static double heightPercentage10(BuildContext context) => MediaQuery.of(context).size.height * 0.1;
  static double heightPercentage20(BuildContext context) => MediaQuery.of(context).size.height * 0.2;
  static double heightPercentage30(BuildContext context) => MediaQuery.of(context).size.height * 0.3;
  static double heightPercentage40(BuildContext context) => MediaQuery.of(context).size.height * 0.4;
  static double heightPercentage50(BuildContext context) => MediaQuery.of(context).size.height * 0.5;
  static double heightPercentage60(BuildContext context) => MediaQuery.of(context).size.height * 0.6;
  static double heightPercentage70(BuildContext context) => MediaQuery.of(context).size.height * 0.7;
  static double heightPercentage80(BuildContext context) => MediaQuery.of(context).size.height * 0.8;
  static double heightPercentage90(BuildContext context) => MediaQuery.of(context).size.height * 0.9;
  static double heightPercentage100(BuildContext context) => MediaQuery.of(context).size.height;

  static double widthPercentage10(BuildContext context) => MediaQuery.of(context).size.width * 0.1;
  static double widthPercentage20(BuildContext context) => MediaQuery.of(context).size.width * 0.2;
  static double widthPercentage30(BuildContext context) => MediaQuery.of(context).size.width * 0.3;
  static double widthPercentage40(BuildContext context) => MediaQuery.of(context).size.width * 0.4;
  static double widthPercentage50(BuildContext context) => MediaQuery.of(context).size.width * 0.5;
  static double widthPercentage60(BuildContext context) => MediaQuery.of(context).size.width * 0.6;
  static double widthPercentage70(BuildContext context) => MediaQuery.of(context).size.width * 0.7;
  static double widthPercentage80(BuildContext context) => MediaQuery.of(context).size.width * 0.8;
  static double widthPercentage90(BuildContext context) => MediaQuery.of(context).size.width * 0.9;
  static double widthPercentage100(BuildContext context) => MediaQuery.of(context).size.width;

  static double heightPercentage(BuildContext context, double percentage) =>
      MediaQuery.of(context).size.height * percentage;
  static double widthPercentage(BuildContext context, double percentage) =>
      MediaQuery.of(context).size.width * percentage;

  static const double formMaxWidthSmall = 200;
  static const double formMaxWidthMedium = 400;
  static const double formMaxWidthLarge = 600;
  static const double formMaxWidthXLarge = 800;
}
