require_relative 'csv_reader'
require_relative 'xlsx_writer'
require_relative 'similarity_checker'

# Comparison matrix generator
def compare_matrix_generator(input_file_path:, filter_conditions:)
  start_time = Time.now
  # Step 1: Read the CSV file and extract "user_id" and "final_submission"
  df = csv_reader(input_file_path, filter_conditions: filter_conditions)
  user_ids = df['user_id'].to_a
  final_submissions = df['final_submission'].to_a
  puts "The size of the df: #{df.nrows}"

  # Step 2: Prepare an empty hash to store all similarity matrices
  similarities = {
    "cosine_similarity" => [],
    "euclidean_similarity" => [],
    "jaccard_similarity" => [],
    "levenshtein_similarity" => [],
    "overlap_similarity" => [],
    "winnowing_similarity" => []
  }

  # Step 3: Calculate the similarity between each text and generate the corresponding matrix
  final_submissions.each_with_index do |text1, i|
    row_cosine = []
    row_euclidean = []
    row_jaccard = []
    row_levenshtein = []
    row_overlap = []
    row_winnowing = []

    final_submissions.each_with_index do |text2, j|
      if i == j
        # Similarity with itself is NaN
        row_cosine << Float::NAN
        row_euclidean << Float::NAN
        row_jaccard << Float::NAN
        row_levenshtein << Float::NAN
        row_overlap << Float::NAN
        row_winnowing << Float::NAN
      else
        # Calculate different similarities
        row_cosine << cosine_similarity(text1, text2)
        row_euclidean << euclidean_similarity(text1, text2)
        row_jaccard << jaccard_similarity(text1, text2)
        row_levenshtein << 1 - normalized_levenshtein_distance(text1, text2)
        row_overlap << overlap_coefficient(text1, text2)
        row_winnowing << winnowing(text1, text2, k=3, w=4)
      end
    end

    similarities["cosine_similarity"] << row_cosine
    similarities["euclidean_similarity"] << row_euclidean
    similarities["jaccard_similarity"] << row_jaccard
    similarities["levenshtein_similarity"] << row_levenshtein
    similarities["overlap_similarity"] << row_overlap
    similarities["winnowing_similarity"] << row_winnowing
  end

  # Step 4: Write the similarity matrix to Excel
  xlsx_writer(user_ids, similarities)

  # Calculate and round the process time
  process_time = (Time.now - start_time).round(2)
  puts "Process Time: #{process_time}s"
  return similarities
end

# Test the function
file_path = 'data/text_data/extracted_behavior_pattern_data.csv'

# Comparing tasks btwn AI users
# filter_conditions = [
#   ->(row) { row['use_all'].to_i == 1 },        # filter rows with column "use_all" == 1
#   ->(row) { row['use_revise'].to_i == 0 },    # filter rows with column "use_revise" == 0
#   ->(row) { row['use_refine'].to_i == 0 },     # filter rows with column "use_refine" == 0
#   ->(row) { row['task_type'] == "CREATIVE" }     # filter rows with column "task_type" == PRACTICAL or CREATIVE
# ]
# Comparing AI users with no AI users
filter_conditions = [
  ->(row) { row['use_ai'].to_i == 0 },        # filter rows with column "use_all" == 1
  ->(row) { row['task_type'] == "PRACTICAL" }     # filter rows with column "task_type" == PRACTICAL or CREATIVE
]

# Corrected call to the function with keyword arguments
similarities = compare_matrix_generator(input_file_path: file_path, filter_conditions: filter_conditions)
