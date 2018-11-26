// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'dart_test.dart' as dart_test;
import 'json_test.dart' as json_test;
import 'markdown_test.dart' as markdown_test;

main() {
  defineReflectiveSuite(() {
    dart_test.main();
    json_test.main();
    markdown_test.main();
  }, name: 'lsp-tool');
}
