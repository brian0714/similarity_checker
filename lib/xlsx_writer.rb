require 'write_xlsx'

# @param [Array] users: A list of user names or IDs
# @param [Hash] similarities: A hash where the key is the similarity algorithm, and the value is the similarity matrix
def xlsx_writer(users, similarities)
  # Define the file path of the output
  output_file_path = "output"

  # Get current datetime as a string (format: YYYYMMDDHHMM)
  datetime = Time.now.strftime("%Y%m%d%H%M")

  # Create a new Excel file based on Datetime
  workbook = WriteXLSX.new("#{output_file_path}/similarity_checker(#{datetime}).xlsx")

  # Create similarity sheets
  similarities.each do |similarity_name, matrix|
    sheet = workbook.add_worksheet(similarity_name)

    # Write similarity matrix
    sheet.write(0, 0, 'user_id') # The upper-left cell is 'user'
    users.each_with_index { |user, i| sheet.write(0, i+1, user) } # write in header
    users.each_with_index do |user, i|
      sheet.write(i+1, 0, user) # write name in each row
      matrix[i].each_with_index do |value, j|
        sheet.write(i+1, j+1, value) # write in the similarity score
      end
    end
  end

  # Close and Save the Excel file
  workbook.close
  puts "Excel file - 'similarity_checker(#{datetime}).xlsx' has been created."
end

# Test
# Given 3 users
users = ["user_1", "user_2", "user_3"]
# Given different similarity matrix
similarities = {
  "cosine_similarity" => [
    [Float::NAN, 0.75, 0.10],
    [0.75, Float::NAN, 0.50],
    [0.10, 0.50, Float::NAN]
  ],
  "euclidean_similarity" => [
    [Float::NAN, 0.80, 0.65],
    [0.80, Float::NAN, 0.55],
    [0.65, 0.55, Float::NAN]
  ]
}
# xlsx_writer(users: users, similarities: similarities)
