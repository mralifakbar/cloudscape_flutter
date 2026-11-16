import 'categories/actions.dart';
import 'categories/board.dart';
import 'categories/charts.dart';
import 'categories/collections.dart';
import 'categories/dates.dart';
import 'categories/display.dart';
import 'categories/editors.dart';
import 'categories/feedback.dart';
import 'categories/forms.dart';
import 'categories/foundation.dart';
import 'categories/genai.dart';
import 'categories/layout.dart';
import 'categories/navigation.dart';
import 'categories/selection.dart';
import 'demo.dart';

/// Every gallery category, in the order the home page lists them.
final List<CsDemoCategory> galleryCategories = [
  foundationCategory,
  formsCategory,
  actionsCategory,
  selectionCategory,
  editorsCategory,
  datesCategory,
  layoutCategory,
  navigationCategory,
  feedbackCategory,
  displayCategory,
  collectionsCategory,
  chartsCategory,
  genaiCategory,
  boardCategory,
];
