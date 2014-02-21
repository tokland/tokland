# encoding: UTF-8
require 'json'
require 'data_mapper'
require 'csv'
require 'nokogiri'
require 'open-uri'
require 'active_support/core_ext/object/blank'
require 'facets/enumerable'
require 'Grammy'
require 'dm-migrations'
require "unicode_utils"

module Dictionary
  class Tag
    include DataMapper::Resource
    storage_names[:default] = "tags"

    property :id, Serial
    property :name, String
    has n, :tag_words
    has n, :words, :through => :tag_words
  end

  class TagWord
    include DataMapper::Resource
    storage_names[:default] = "tag_words"

    property :id, Serial
    belongs_to :tag
    belongs_to :word
  end

  class Word
    include DataMapper::Resource
    storage_names[:default] = "words"

    property :id, Serial
    property :name, String, :index => true
    property :syllables, String
    property :accent, Integer, :index => true
    has n, :tag_words
    has n, :tags, :through => :tag_words
  end

  DataMapper.finalize

  def self.syllables(word0)
    exceptions = {
      "sfumato" => [["s", "fu", "ma", "to"], 1],
      "striptease" => [["s", "trip", "tease"], 1],
    }
    
    grammar = Grammy.define do
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
      rule prefix => ("des" | "en" | "subs") >> lookahead(vowel) # mmm, no sempre seguit de vocal
      
      # syllable
      rule syllable_start =>
        prefix | raising_diphtong_unit | consonantic_vowel_unit | (~consonant >> vowel_group)
      rule consonantic_syllable_end => 
        (+consonant >> eos) |
        lookahead(consonantic_unit) |
        (consonant >> consonantic_syllable_end? >> lookahead(consonant))
      
      rule syllable => syllable_start >> consonantic_syllable_end?
      start word => ~syllable
      
      # accents
      rule raising_diphtong_start => 
        ('q' | 'g') >>
          ('u' >> lookahead(falling_diphthong | a | o) |
           'ü' >> lookahead(falling_diphthong | e | i))
      rule accent_exception_termination => (falling_diphthong >> [s | n]) >> eos
      rule accent_termination => 
        ((a >> s) | (e >> s) | (i >> s) | (o >> s) | (u >> s) |
        (e >> n) | (i >> n) |
        a | e | i | o | u) >> eos
      rule accent => 
        ~(raising_diphtong_start | consonant | consonantic_vowel) >> 
        (accent_exception_termination | accent_termination)
    end
    
    word = UnicodeUtils.downcase(word0)
    if exceptions.include?(word)
      exceptions[word]
    else
      syllables = grammar.parse(word.gsub(/-/, '')).tree.children.map do |node|
        node.data.gsub(/·/, '')
      end
      accent_index = syllables.reverse.map.with_index do |s, i|
        s.match(/[àéèíòóùú]/) ? i : nil
      end.compact.first
      
      position = case
      when accent_index
        accent_index
      when syllables.size <= 1
        0
      else
        children = grammar.parse(syllables.last, :rule => :accent).tree.children
        (children.present? && children.last.name == :accent_termination) ? 1 : 0
      end
      [syllables, position]
    end
  end

  class TagsParser
    def initialize(options = {})
      @abbreviations = JSON.parse(File.read("abbreviations.json"))
      @options = options
    end
    
    def debug(*args)
      puts(*args) if @options[:debug]
    end
 
    def process_word(path)
      html = open(path, 'r:iso-8859-1').read
      doc = Nokogiri::HTML(html.gsub(/[[:space:]]+/, ' '))
      known_keys = @abbreviations.keys
      tables = doc.css("td.CentreTextTD > table").presence || doc.css("table")
      
      pairs = tables.flat_map do |section|
        trs = section.css("tr")
        name_tag = trs.first
        extra_tags = trs.drop(1)
        names = name_tag.at_css(".enc").xpath('text()').text.split.map(&:strip)
        has_gender = (names.size == 2) 
        names.map.with_index do |name0, idx|
          name = name0.start_with?("-") ?
            names.first.sub(/[aàeéèiíoóòuú]$/, '') + name0[1..-1] : name0
          is_masculine = (has_gender && idx == 0)
          is_femenine = (has_gender && idx == 1)
          text_nodes = section.css("tr:not(:first-child)").xpath(".//text()")
          candidates = text_nodes.flat_map { |t| t.text.split("/").map(&:strip) } 
          keys = (candidates & known_keys) -
            (is_masculine ? ["f"] : []) -
            (is_femenine ? ["m"] : []) |
            (is_masculine ? ["m"] : []) |
            (is_femenine ? ["f"] : []) 
          [name, keys]
        end
      end
      pairs.map_by { |k, vs| [k, vs] }.mash { |k, vss| [k, vss.flatten(1)] }  
    end
    
    def write(path, contents)
      File.write(path, contents)
      path
    end
    
    def generate(paths, format)
      words = paths.flat_map do |path|
        process_word(path).map do |name, tags|
          syllables, accent = Dictionary.syllables(name)
          {name: name, tags: tags, syllables: syllables, accent: accent} 
        end
      end
      generate_words(words, format)
    end 
    
    def generate_words(words, format)
      case format.to_sym
      when :all
        [:txt, :json, :csv, :sql].map do |format|
          generate_words(words, format)
        end.join("\n")
      when :txt
        contents = words.map do |word|
          "#{word[:name]}: (#{word[:syllables].join('-')}:#{word[:accent]}) #{word[:tags].join(', ')}"
        end.join("\n")
        write("words.txt", contents)
      when :json
        words2 = words.mash do |word|
          data = {:tags => word[:tags], :syllables => word[:syllables].join('-'), :accent => word[:accent]}
          [word, data]
        end
        contents = JSON.pretty_generate(words2)
        write("words.json", contents)
      when :csv
        contents = CSV.generate do |csv|
          csv << ["word", "syllables", "accent", "tags"]
          words.map do |word|
            csv << [word[:name], word[:syllables].join('-'), word[:accent], word[:tags].join('|')]
          end 
        end
        write("words.csv", contents)
      when :sql
        path = "words.sqlite3"
        File.unlink(path) if File.exists?(path)
        DataMapper.setup(:default, 'sqlite:' + path)
        DataMapper.auto_migrate!
        
        words.flat_map { |word| word[:tags] }.uniq.each do |tag_name|
          Tag.create(:name => tag_name)
        end
        
        words.each do |word|
          Word.create({
            :name => word[:name], 
            :tags => Tag.all(:name => word[:tags]),
            :syllables => word[:syllables].join('-'),
            :accent => word[:accent],
          })
        end
        path
      end 
    end
  end
end

if __FILE__ == $0
  format, path_pattern = ARGV
  dict = Dictionary::TagsParser.new(:debug => true)
  puts(dict.generate(Dir.glob(path_pattern).sort, format))
end
