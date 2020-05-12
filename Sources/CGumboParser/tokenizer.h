#ifndef GUMBO_TOKENIZER_H_
#define GUMBO_TOKENIZER_H_

// This contains an implementation of a tokenizer for HTML5. It consumes a
// buffer of UTF-8 characters, and then emits a stream of tokens.

#include <stdbool.h>
#include <stddef.h>

#include "gumbo.h"
#include "token_type.h"
#include "tokenizer_states.h"

struct GumboParser;

// Struct containing all information pertaining to doctype tokens.
typedef struct GumboTokenDocType {
  const char* name;
  const char* public_identifier;
  const char* system_identifier;
  bool force_quirks;
  // There's no way to tell a 0-length public or system ID apart from the
  // absence of a public or system ID, but they're handled different by the
  // spec, so we need bool flags for them.
  bool has_public_identifier;
  bool has_system_identifier;
} GumboTokenDocType;

// Struct containing all information pertaining to start tag tokens.
typedef struct GumboTokenStartTag {
  GumboTag tag;
  GumboVector /* GumboAttribute */ attributes;
  bool is_self_closing;
} GumboTokenStartTag;

// A data structure representing a single token in the input stream. This
// contains an enum for the type, the source position, a GumboStringPiece
// pointing to the original text, and then a union for any parsed data.
typedef struct GumboToken {
  GumboTokenType type;
  GumboSourcePosition position;
  GumboStringPiece original_text;
  union {
    GumboTokenDocType doc_type;
    GumboTokenStartTag start_tag;
    GumboTag end_tag;
    const char* text;  // For comments.
    int character;     // For character, whitespace, null, and EOF tokens.
  } v;
} GumboToken;

// Initializes the tokenizer state within the GumboParser object, setting up a
// parse of the specified text.
void gumbo_tokenizer_state_init (
  struct GumboParser* parser,
  const char* text,
  size_t text_length
);

// Destroys the tokenizer state within the GumboParser object, freeing any
// dynamically-allocated structures within it.
void gumbo_tokenizer_state_destroy(struct GumboParser* parser);

// Sets the tokenizer state to the specified value. This is needed by some
// parser states, which alter the state of the tokenizer in response to tags
// seen.
void gumbo_tokenizer_set_state (
  struct GumboParser* parser,
  GumboTokenizerEnum state
);

// Flags whether the current node is a foreign content element. This is
// necessary for the markup declaration open state, where the tokenizer must be
// aware of the state of the parser to properly tokenize bad comment tags.
// https://html.spec.whatwg.org/multipage/parsing.html#markup-declaration-open-state
void gumbo_tokenizer_set_is_current_node_foreign (
  struct GumboParser* parser,
  bool is_foreign
);

// Lexes a single token from the specified buffer, filling the output with the
// parsed GumboToken data structure. Returns true for a successful
// tokenization, false if a parse error occurs.
//
// Example:
//   struct GumboParser parser;
//   GumboToken output;
//   gumbo_tokenizer_state_init(&parser, text, strlen(text));
//   while (gumbo_lex(&parser, &output)) {
//     ...do stuff with output.
//     gumbo_token_destroy(&token);
//   }
//   gumbo_tokenizer_state_destroy(&parser);
bool gumbo_lex(struct GumboParser* parser, GumboToken* output);

// Frees the internally-allocated pointers within a GumboToken. Note that this
// doesn't free the token itself, since oftentimes it will be allocated on the
// stack.
//
// Note that if you are handing over ownership of the internal strings to some
// other data structure - for example, a parse tree - these do not need to be
// freed.
void gumbo_token_destroy(GumboToken* token);

#endif // GUMBO_TOKENIZER_H_
