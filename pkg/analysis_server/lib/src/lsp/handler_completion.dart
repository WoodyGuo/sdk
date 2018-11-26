// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';

// If the client does not provide capabilities.completion.completionItemKind.valueSet
// then we must never send a kind that's not in this list.
final defaultSupportedCompletionKinds = new HashSet<CompletionItemKind>.of([
  CompletionItemKind.Text,
  CompletionItemKind.Method,
  CompletionItemKind.Function,
  CompletionItemKind.Constructor,
  CompletionItemKind.Field,
  CompletionItemKind.Variable,
  CompletionItemKind.Class,
  CompletionItemKind.Interface,
  CompletionItemKind.Module,
  CompletionItemKind.Property,
  CompletionItemKind.Unit,
  CompletionItemKind.Value,
  CompletionItemKind.Enum,
  CompletionItemKind.Keyword,
  CompletionItemKind.Snippet,
  CompletionItemKind.Color,
  CompletionItemKind.File,
  CompletionItemKind.Reference,
]);

class CompletionHandler
    extends MessageHandler<CompletionParams, List<CompletionItem>> {
  CompletionHandler(LspAnalysisServer server) : super(server);
  Method get handlesMessage => Method.textDocument_completion;

  @override
  CompletionParams convertParams(Map<String, dynamic> json) =>
      CompletionParams.fromJson(json);

  Future<List<CompletionItem>> handle(CompletionParams params) async {
    final path = pathOf(params.textDocument);
    final result = await requireUnit(path);
    final offset = toOffset(result.lineInfo, params.position);

    final completionCapabilities =
        server.clientCapabilities.textDocument != null
            ? server.clientCapabilities.textDocument.completion
            : null;

    final clientSupportedCompletionKinds = completionCapabilities != null &&
            completionCapabilities.completionItemKind != null &&
            completionCapabilities.completionItemKind.valueSet != null
        ? new HashSet<CompletionItemKind>.of(
            completionCapabilities.completionItemKind.valueSet)
        : defaultSupportedCompletionKinds;

    final performance = new CompletionPerformance();
    final completionRequest =
        new CompletionRequestImpl(result, offset, performance);

    try {
      CompletionContributor contributor = new DartCompletionManager();
      final items = await contributor.computeSuggestions(completionRequest);
      return items
          .map((item) => toCompletionItem(
                completionCapabilities,
                clientSupportedCompletionKinds,
                result.lineInfo,
                item,
                completionRequest.replacementOffset,
                completionRequest.replacementLength,
              ))
          .toList();
    } on AbortCompletion {
      return [];
    }
  }
}
