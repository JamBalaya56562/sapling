/**
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import type {IRawGrammar, IRawTheme} from 'vscode-textmate';
import type {Grammar, TextMateGrammar} from './types';

import {createOnigScanner, createOnigString} from 'vscode-oniguruma';
import {Registry, parseRawGrammar} from 'vscode-textmate';

/**
 * Caller is responsible for ensuring `loadWASM()` from `vscode-oniguruma` has
 * been called (and resolved successfully) before calling this function.
 */
export default function createTextMateRegistry(
  theme: IRawTheme,
  grammars: {[scopeName: string]: Grammar},
  fetchGrammar: (
    fileName: string,
    fileFormat: 'json' | 'plist',
    base: string,
  ) => Promise<TextMateGrammar>,
  base: string,
): Registry {
  return new Registry({
    theme,
    onigLib: Promise.resolve({
      createOnigScanner,
      createOnigString,
    }),

    async loadGrammar(scopeName: string): Promise<IRawGrammar | undefined | null> {
      const config = grammars[scopeName];
      if (config != null) {
        const {type, grammar} = await fetchGrammar(config.fileName, config.fileFormat, base);
        // If this is a JSON grammar, filePath must be specified with a `.json`
        // file extension or else parseRawGrammar() will assume it is a PLIST
        // grammar.
        const filePath = `example.${type}`;
        return parseRawGrammar(grammar, filePath);
      } else {
        // text.html.markdown supports a ton of embedded languages, but we do
        // not bundle all of them, so we can expect to get requests for
        // languages we cannot satisfy. Because this this expected, we return
        // null rather than throw an error.
        return Promise.resolve(null);
      }
    },

    /**
     * For the given scope, returns a list of additional grammars that should be
     * "injected into" it (i.e., a list of grammars that want to extend the
     * specified `scopeName`). The most common example is other grammars that
     * want to "inject themselves" into the `text.html.markdown` scope so they
     * can be used with fenced code blocks.
     *
     * In the manifest of a VS Code extension, a grammar signals that it wants
     * to do this via the "injectTo" property:
     * https://code.visualstudio.com/api/language-extensions/syntax-highlight-guide#injection-grammars
     */
    getInjections(scopeName: string): Array<string> | undefined {
      const grammar = grammars[scopeName];
      return grammar?.injections ?? undefined;
    },
  });
}
