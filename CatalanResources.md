# Introduction #

Using http://www.diccionaris.cat as source, get the tags and syllable division (automatic process, see section below) for each word. The tags can be found [here](http://www.diccionari.cat/abrev.jsp?ABRE=L). Example:

```
# word: (syllables:accent): tags
àbac: (à-bac:1) m, MAT, m, ARQUIT, CONSTR, MOBL
abacà: (a-ba-cà:0) m, BOT, AGR, TÈXT
abacallanar-se: (a-ba-ca-lla-nar-se:1) v, pron
abacial: (a-ba-ci-al:0) adj
abaciologi: (a-ba-ci-o-lo-gi:1) m, HIST ECL
abacista: (a-ba-cis-ta:1) HIST, m, f, adj
abacomtat: (a-ba-com-tat:0) m, HIST
abacomte: (a-ba-com-te:1) m, HIST
```

# Download #

Download [TXT, JSON, CSV and SQLITE3 files](http://download.zaudera.com/public/catalan-words-tags-syllables.tgz).

# Syllable division #

Using the rules found [here](http://www.aldeaglobal.net/cat5estrelles/Accentuacio.htm) we can define a [BNF grammar](http://en.wikipedia.org/wiki/Backus%E2%80%93Naur_Form) using [grammy](https://github.com/tokland/grammy):

```
# letters
rule a => 'a' | 'à'
rule e => 'e' | 'è' | 'é'
rule i => 'i' | 'í'
rule o => 'o' | 'ó' | 'ò'
rule u => 'u' | 'ú'
rule vowel => a | e | i | 'ï' | o | u | 'ü'
"gqhxrsn".chars.each { |k| rule(send(k) => k) }

# diphtongs
rule falling_diphthong =>
  ((a >> i) | (e >> i) | (i >> i) | (o >> i) | (u >> i) |
   (a >> u) | (e >> u) | (i >> u) | (o >> u) | (u >> u)) >> lookahead_negative(vowel)
rule raising_diphtong_unit =>
  ('q' | 'g') >>
    ('u' >> (falling_diphthong | a | o) |
     'ü' >> (falling_diphthong | e | i))

# dygraphs
rule non_separable_dygraph =>
  "ny" | "ll" | "ch" | ((q | g) >> 'u' >> lookahead(e | i)) | ('ig' >> eos)
rule dygraph_ix => 'i' >> lookahead(x)
rule dygraph_dotl => '·l'
rule dygraph_l_geminate => 'l' >> lookahead(dygraph_dotl)
rule dygraph_rr => r >> lookahead(r)
rule dygraph_ss => s >> lookahead(s)
rule separable_dygraph => dygraph_ix | dygraph_l_geminate | dygraph_rr | dygraph_ss
rule dygraph => non_separable_dygraph | separable_dygraph

# consonantic
rule consonantic_unit =>
  'bl' | 'br' | 'cl'| 'cr'| 'dr' | 'fl' | 'gl' | 'gr' | 
  'pl' | 'pr' | 'tr' | non_separable_dygraph
rule non_consonantic_vowel => a | e | o
rule consonantic_vowel => ('i' | 'u') >> lookahead(non_consonantic_vowel)
rule consonantic_vowel_unit => 
  ((h? >> consonantic_vowel) >> ((vowel_group >> eos) | vowel))
rule vowel_group => ((consonantic_vowel? >> falling_diphthong) | vowel)
rule consonant => dygraph | dygraph_dotl | /[bcçdfghjklmnpqrstvwxyz]/

# special
rule prefix => ("des" | "en" | "subs") >> lookahead(vowel)

# syllable
rule syllable_start =>
  prefix | raising_diphtong_unit | consonantic_vowel_unit | (~consonant >> vowel_group)
rule consonantic_syllable_end => 
  (+consonant >> eos) |
  lookahead(consonantic_unit) |
  (consonant >> consonantic_syllable_end? >> lookahead(consonant))

rule syllable => syllable_start >> consonantic_syllable_end?
start word => ~syllable
```

# Source code #

Get the code:

```
$ svn checkout https://tokland.googlecode.com/svn/trunk/dicts/catala/metadata
```

Run:

```
$ ruby get_tags.rb
$ ruby download-all.rb
$ ruby dictionary.rb all 'output/*.html'
```

[Tags: català, diccionari, divisió síl.labes, accent, rima, nom, adjectiu, verb, adverb, preposició, base de dades]