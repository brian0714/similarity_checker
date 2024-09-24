# frozen_string_literal: true

require 'set'
require 'matrix'
require 'csv'
require 'digest'
require 'stemmer'
require ''

# Calculate Euclidean Similarity
def euclidean_similarity(text1, text2, tokenize_method=:word, vectorize_method=:bow)
  # Tokenize two texts
  tokens1 = tokenize(text1, tokenize_method)
  tokens2 = tokenize(text2, tokenize_method)

  # 合併所有 token 作為詞彙表
  all_tokens = (tokens1 + tokens2).uniq

  # 使用不同的向量化方法
  vec1, vec2 = case vectorize_method
               when :bow
                 [bow_vectorize(tokens1, all_tokens), bow_vectorize(tokens2, all_tokens)]
               when :one_hot
                 [one_hot_vectorize(tokens1, all_tokens), one_hot_vectorize(tokens2, all_tokens)]
               else
                 raise "Unknown vectorize method: #{vectorize_method}"
               end

  # 檢查向量長度是否一致
  raise "Vectors must have the same length" if vec1.length != vec2.length

  # 計算歐幾里得距離
  distance = Math.sqrt(vec1.zip(vec2).map { |a, b| (a - b) ** 2 }.reduce(:+))

  # 計算相似度（歐幾里得相似度）
  similarity = 1 / (1 + distance)
  return similarity
end


# Calculate Jaccard similarity between two texts
def jaccard_similarity(text1, text2)
  # Create a set of unique words. This means that duplicate words in text content are ignored.
  set1 = Set.new(text1.split)
  set2 = Set.new(text2.split)
  # Calculate the number of words common to both set1 and set2 (the intersection).
  intersection = set1.intersection(set2).length.to_f
  # Combine the words from both sets (the union), ensuring each word is unique in this combined set.
  union = set1.union(set2).length.to_f
  # Dividing the size of the intersection by the size of the union.
  intersection / union
end

def jaccard_similarity_with_bigrams(text1, text2)
  # Convert the texts into arrays of words.
  words1 = text1.split
  words2 = text2.split

  # Create bigrams (pairs of consecutive words).
  bigrams1 = words1.each_cons(2).to_set
  bigrams2 = words2.each_cons(2).to_set
  # Calculate the intersection and union of the bigrams.
  intersection = bigrams1.intersection(bigrams2).length.to_f
  union = bigrams1.union(bigrams2).length.to_f
  # Calculate Jaccard similarity.
  intersection / union
end

# Calculate Cosine similarity between two texts
def word_frequencies(text)
  freq = Hash.new(0)
  text.split.each { |word| freq[word] += 1 }
  freq
end

def cosine_similarity(text1, text2)
  freq1 = word_frequencies(text1)
  freq2 = word_frequencies(text2)

  common = freq1.keys & freq2.keys
  vectors = common.map { |f| [freq1[f], freq2[f]] }.transpose
  vec1 = Vector.elements(vectors.first)
  vec2 = Vector.elements(vectors.last)

  vec1.inner_product(vec2) / (vec1.magnitude * vec2.magnitude)
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
def tokenize(text)
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

def winnowing(doc1, doc2, k, w)
  tokens1 = tokenize(doc1)
  tokens2 = tokenize(doc2)

  hashes1 = hash_tokens(tokens1)
  hashes2 = hash_tokens(tokens2)

  k_grams1 = k_grams(hashes1, k)
  k_grams2 = k_grams(hashes2, k)

  fingerprints1 = fingerprints(k_grams1, w)
  fingerprints2 = fingerprints(k_grams2, w)

  matches = fingerprints1 & fingerprints2
  matches.length.to_f / [fingerprints1.length, fingerprints2.length].min
end

# def plagiarism_checker(directory, output_file)
#   k = 3 # Size of k-grams
#   w = 4 # Size of the window
#   files_content = read_files(directory)

#   # Open CSV file for writing
#   CSV.open(output_file, 'w') do |csv|
#     # Define CSV headers including execution times for each algorithm
#     csv << ["File 1", "File 2", "Jaccard Similarity", "Jaccard Similarity Execution Time (s)", "Jaccard Similarity with Bigrams", "Jaccard with Bigrams Execution Time (s)", "Cosine Similarity", "Cosine Similarity Execution Time (s)", "Overlap Coefficient", "Overlap Coefficient Execution Time (s)", "Normalized Levenshtein Distance", "Normalized Levenshtein Distance Execution Time (s)", "Normalized Hamming Distance", "Normalized Hamming Distance Execution Time (s)", "Winnowing", "Winnowing Execution Time (s)"]

#     files_content.keys.combination(2).each do |file1, file2|
#       text1 = files_content[file1]
#       text2 = files_content[file2]
#       start_time = Time.now
#       jaccard = jaccard_similarity(text1, text2)
#       jaccard_time = Time.now - start_time

#       start_time = Time.now
#       jaccard_with_bigrams = jaccard_similarity_with_bigrams(text1, text2)
#       jaccard_with_bigrams_time = Time.now - start_time

#       start_time = Time.now
#       cosine = cosine_similarity(text1, text2)
#       cosine_time = Time.now - start_time
cosine_similarity(text1, text2)
overlap_coefficient(text1, text2)
1 - normalized_levenshtein_distance(text1, text2)
winnowing(text1, text2, k=3, w=4)

#       start_time = Time.now
#       overlap = overlap_coefficient(text1, text2)
#       overlap_time = Time.now - start_time

#       start_time = Time.now
#       levenshtein = 1 - normalized_levenshtein_distance(text1, text2)
#       levenshtein_time = Time.now - start_time

#       hamming_time = 0
#       hamming = "N/A"
#       if text1.length == text2.length
#         start_time = Time.now
#         hamming = 1 - normalized_hamming_distance(text1, text2)
#         hamming_time = Time.now - start_time
#       end

#       start_time = Time.now
#       winnowing = winnowing(text1, text2, k, w)
#       winnowing_time = Time.now - start_time

#       # Write to CSV
#       csv << [
#         File.basename(file1), File.basename(file2),
#         jaccard.round(2), jaccard_time.round(4),
#         jaccard_with_bigrams.round(2), jaccard_with_bigrams_time.round(4),
#         cosine.round(2), cosine_time.round(4),
#         overlap.round(2), overlap_time.round(4),
#         levenshtein.round(2), levenshtein_time.round(4),
#         hamming, hamming_time.round(4),
#         winnowing.round(2), winnowing_time.round(4)
#       ]
#     end
#   end
# end

# Usage
text1 = "During weekends, I like to read."
text2 = "I love to read on Saturday and Sunday."
puts jaccard_similarity(text1, text2)
puts jaccard_similarity_with_bigrams(text1, text2)