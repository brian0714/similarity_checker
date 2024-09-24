# frozen_string_literal: true

require 'set'
require 'matrix'
require 'csv'
require 'digest'
require 'stemmer'
require_relative 'NLP_vectorizer'

# Calculate Euclidean similarity
def euclidean_similarity(text1, text2, tokenize_method=:word, vectorize_method=:bow)
  vec1, vec2 = text_vectorizer(text1, text2, tokenize_method, vectorize_method)

  # Check whether the length is identical
  raise "Vectors must have the same length" if vec1.length != vec2.length

  # Calculate Euclidean distance
  distance = Math.sqrt(vec1.zip(vec2).map { |a, b| (a - b) ** 2 }.reduce(:+))

  # Calculate Euclidean similarity
  similarity = 1 / (1 + distance)
  return similarity
end

def jaccard_similarity(text1, text2, ngram=nil)
  # Split the texts into arrays of words.
  words1 = text1.split
  words2 = text2.split

  if ngram
    # Create n-grams (e.g. bigrams)
    ngram = ngram.to_i
    set1 = words1.each_cons(ngram).to_set
    set2 = words2.each_cons(ngram).to_set
  else
    # Create sets of unique words (ignoring duplicates).
    set1 = Set.new(words1)
    set2 = Set.new(words2)
  end

  # Calculate the intersection and union of the two sets.
  intersection = set1.intersection(set2).length.to_f
  union = set1.union(set2).length.to_f

  # Return the Jaccard similarity (intersection over union).
  intersection / union
end

# Calculate Cosine similarity between two texts
def word_frequencies(text)
  freq = Hash.new(0)
  text.split.each { |word| freq[word] += 1 }
  freq
end

# Calculate Cosine similarity between two texts
def cosine_similarity(text1, text2)
  freq1 = word_frequencies(text1)
  freq2 = word_frequencies(text2)

  # Get the common words in both texts
  common = freq1.keys & freq2.keys

  # Similarity will be 0 if no common words
  if common.empty?
    return 0.0
  end

  # Create vectors for the common words
  vectors = common.map { |f| [freq1[f], freq2[f]] }.transpose

  vec1 = Vector.elements(vectors.first || []) # Return empty array if vectors are null
  vec2 = Vector.elements(vectors.last || [])  # Return empty array if vectors are null

  # Handle zero magnitude cases
  if vec1.magnitude.zero? || vec2.magnitude.zero?
    return 0.0
  end

  # Calculate cosine similarity
  rounded_result = (vec1.inner_product(vec2) / (vec1.magnitude * vec2.magnitude)).round(2)
end

# Calculate Levenshtein Distance between two texts
def levenshtein_distance(str1, str2)
  # Handling the cases where one of the strings is empty
  return str1.length if str2.empty?
  return str2.length if str1.empty?

  m, n = str1.length, str2.length
  d = Array.new(m + 1) { Array.new(n + 1) }

  # Initialize the first row and column of the matrix
  (0..m).each { |i| d[i][0] = i }
  (0..n).each { |j| d[0][j] = j }

  # Fill in the matrix using dynamic programming
  (1..m).each do |i|
    (1..n).each do |j|
      cost = str1[i - 1] == str2[j - 1] ? 0 : 1
      d[i][j] = [d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost].min
    end
  end

  d[m][n]
end

# Normalize Levenshtein Distance
def normalized_levenshtein_distance(text1, text2)
  max_length = [text1.length, text2.length].max
  levenshtein_distance(text1, text2).to_f / max_length
end

# Calculate Hamming Distance between two texts
def hamming_distance(str1, str2)
  raise 'Strings must be of equal length' unless str1.length == str2.length

  str1.chars.zip(str2.chars).count { |a, b| a != b }
end

# Normalize Hamming Distance
def normalized_hamming_distance(str1, str2)
  hamming_distance(str1, str2).to_f / str1.length
end

# Calculate Overlap Coefficient between two texts
def overlap_coefficient(text1, text2)
  set1 = Set.new(text1.split)
  set2 = Set.new(text2.split)
  intersection = set1.intersection(set2).length.to_f
  intersection / [set1.length, set2.length].min.to_f
end

# Winnowing Algorithm
def winnow_tokenize(text)
  text.downcase.scan(/\w+/)
end

def hash_tokens(tokens)
  tokens.map { |token| Digest::SHA1.hexdigest(token)[0, 8].to_i(16) }
end

def k_grams(hashes, k)
  hashes.each_cons(k).to_a
end

def fingerprints(k_grams, w)
  window_min = []
  k_grams.each_cons(w) do |window|
    window_min << window.min_by { |k_gram| k_gram.first }
  end
  window_min.uniq
end

# (k = 3 if size = 100~200 | w = k+1 or k+2)
def winnowing(doc1, doc2, k, w)
  tokens1 = tokenize(doc1, method=:word) # winnow_tokenize(doc1)
  tokens2 = tokenize(doc2, method=:word) # winnow_tokenize(doc2)

  hashes1 = hash_tokens(tokens1)
  hashes2 = hash_tokens(tokens2)

  k_grams1 = k_grams(hashes1, k)
  k_grams2 = k_grams(hashes2, k)

  fingerprints1 = fingerprints(k_grams1, w)
  fingerprints2 = fingerprints(k_grams2, w)

  # Check the value of fingerprints to avoid division-by-zero error
  return 0.0 if fingerprints1.empty? || fingerprints2.empty?

  matches = fingerprints1 & fingerprints2
  matches.length.to_f / [fingerprints1.length, fingerprints2.length].min
end

# Usage

# Case 1 - Similar texts
text1 = "I like to read."
text2 = "I love to read."

# Case 2 - Similar meanings but different texts
# text1 = "During weekends, I like to read books."
# text2 = "I love to read books on Saturday and Sunday."

# Case 3 - Different texts
# text1 = "The research is about similarity calculation."
# text2 = "Multiple methods are based on NLP."

# puts "jaccard_similarity: #{jaccard_similarity(text1, text2)}"
# puts "jaccard_similarity_with_bigrams: #{jaccard_similarity(text1, text2, ngram=2)}"

# puts "cosine_similarity: #{cosine_similarity(text1, text2)}"
# puts "overlap_similarity: #{overlap_coefficient(text1, text2)}"
# puts "levenshtein_similarity: #{1 - normalized_levenshtein_distance(text1, text2)}"
# puts "winnowing_similarity: #{winnowing(text1, text2, k=3, w=4)}"

# puts "euclidean_similarity: #{euclidean_similarity(text1, text2, tokenize_method=:word, vectorize_method=:bow)}"