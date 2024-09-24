require 'daru'
require 'csv'

# csv_reader
def csv_reader(csv_file_path, filter_conditions: [], num_rows: nil)
  # Read CSV data
  data = CSV.read(csv_file_path, headers: true)

  # Transform CSV into hash-format and create into DataFrame
  data_hash = data.map(&:to_h)
  df = Daru::DataFrame.new(data_hash)

  # Transform user_id as integer and sorting in ascending order
  df['user_id'] = df['user_id'].map(&:to_i)
  df = df.sort(['user_id'])

  # Applying multiple filter conditions
  unless filter_conditions.empty?
    df = df.filter_rows do |row|
      filter_conditions.all? { |condition| condition.call(row) }
    end
  end

  # Return head "n" of rows as a filtered data if specified num_rows
  df = df.head(num_rows) if num_rows

  return df
end

# test
# Set the input file path
file_path = 'data/text_data/extracted_behavior_pattern_data.csv'

# Define multiple (single) conditions
# filter_conditions = [
#   ->(row) { row['use_ai'].to_i == 1 },        # filter rows with column "use_ai" == 1
#   ->(row) { row['use_revise'].to_i == 0 },    # filter rows with column "use_revise" == 0
# ]
# filter_conditions = [
#   ->(row) { row['use_ai'].to_i == 1 },        # filter rows with column "use_ai" == 1
# ]

# df = csv_reader(file_path, filter_conditions: filter_conditions)
# puts df.nrows