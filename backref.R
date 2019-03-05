rematch2::re_match(c(
  "<A>barsfagf</A>",
  "<P>badasdar</P>",
  "<IMG>sadjkl</IMG>",
  "<A>bdasagar</P>"),

  "<([A-Z]+)>.*?</\\1>")

re2r::re2_match("<A>bar</A>", "<([A-Z])>.*?</\\1>")#bad escape sequence: \1
stringi::stri_match_first_regex("<A>bar</A>", "<([A-Z])>.*?</\\1>")
gregexpr("<([A-Z])>.*?</\\1>", "<A>bar</A>", perl=TRUE)
gregexpr("<([A-Z])>.*?</\\1>", "<A>bar</A>", perl=FALSE)

