# mimestrip

This script takes a text/rfc822 message, strips out all but the first
plain-text part (or converting the first HTML part to plain text if
there is no plain-text part), and word-wraps the plain-text part.  The
original message is read from stdin and the modified message is
written to stdout.

This is intended as a replacement for [Alex
Wetmore](https://www.phred.org/~alex/)'s
[Stripmime](https://www.phred.org/~alex/stripmime.html), which has the
unfortunate behaviour of folding rather than wrapping quoted-printable
messages at column 75.
