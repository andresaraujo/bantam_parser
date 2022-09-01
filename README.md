This a dart implementation of [Bantam](https://journal.stuffwithstuff.com/2011/03/19/pratt-parsers-expression-parsing-made-easy/)

This was my attempt of learning how Pratt parsers work, as well as playing around with 
having an on demand scanner hooked up to the parser.

Some differences from the original:
- It supports more tokens than the original, like `#` for comments and literals.
- Scanner and parser consume tokens on demand, instead of all at once.
