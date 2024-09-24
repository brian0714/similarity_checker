require 'matrix'
require 'stemmer'
require 'stopwords'
require 'tf-idf-similarity'

# Bag-of-Words Vectorizer
def bow_vectorize(tokens, all_tokens)
    all_tokens.map { |token| tokens.count(token) }
end

# One-hot Encoding Vectorizer
def one_hot_vectorize(tokens, all_tokens)
    all_tokens.map { |token| tokens.include?(token) ? 1 : 0 }
end

# TF-IDF Vectorizer
def tfidf_vectorize(texts)
    # Create TF-IDF document-set
    corpus = TfIdfSimilarity::Corpus.new
    puts "corpus: #{corpus}"
    texts.each { |text| corpus.add_document(TfIdfSimilarity::Document.new(text)) }
    puts "corpus: #{corpus}"
    model = TfIdfSimilarity::TfIdfModel.new(corpus)

    # Get the vectorized text
    vectors = texts.map { |text| model.document_vector(corpus.documents.find { |doc| doc.text == text }) }
    vectors
end

# Tokenization methods
def tokenize(text, method=:word)
    case method
    when :word
      tokens = text.downcase.split(/\W+/).map(&:stem) # word (per vocabulary) split with stemming approach
    when :character
      tokens = text.chars # split per letter
    when :bigram
      tokens = text.downcase.scan(/(?=(\w\w))/).flatten # 2-gram split
    when :trigram
      tokens = text.downcase.scan(/(?=(\w\w\w))/).flatten # 3-gram split
    else
      raise "Unknown tokenization method: #{method}"
    end
    tokens
end

# Use Stopwords gem to remove stopwords
def remove_stopwords(tokens)
    # stopwords_filter = Stopwords::Filter.new("en")
    # tokens.reject { |token| stopwords_filter.stopword?(token) }

    stopwords = Stopwords::STOP_WORDS
    tokens.reject { |token| stopwords.include?(token.downcase) }
end

# Text Vectorizer
def text_vectorizer(text1, text2, tokenize_method, vectorize_method)
    # Tokenize texts
    tokens1 = remove_stopwords(tokenize(text1, tokenize_method))
    tokens2 = remove_stopwords(tokenize(text2, tokenize_method))

    # Merge all tokens
    all_tokens = (tokens1 + tokens2).uniq

    # Different vectorize methods
    vec1, vec2 = case vectorize_method
                when :bow
                    [bow_vectorize(tokens1, all_tokens), bow_vectorize(tokens2, all_tokens)]
                when :one_hot
                    [one_hot_vectorize(tokens1, all_tokens), one_hot_vectorize(tokens2, all_tokens)]
                when :tfidf
                    tfidf_vectors = tfidf_vectorize([text1, text2])
                    [tfidf_vectors[0], tfidf_vectors[1]]
                else
                    raise "Unknown vectorize method: #{vectorize_method}"
                end
    return vec1, vec2
end
