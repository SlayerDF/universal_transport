# frozen_string_literal: true

require "digest/md5"
require "fileutils"
require "pathname"

CORE_CATALOG_GLOB_FILTER = "[0-9][0-9].cat"
MOD_CATALOG_GLOB_FILTER = "ext_[0-9][0-9].cat"

def read_catalog(catalog_path, output_dir, filter_extensions: nil)
  puts "Reading catalog file \"#{catalog_path}\""

  data_path = Pathname.new(catalog_path).sub_ext(".dat").to_s

  file_lines = File.foreach(catalog_path).count

  File.open(data_path, "r") do |data_file|
    line_count = 0

    File.open(catalog_path, "r").each_line do |line|
      line_count += 1

      *filepath, size, modified_at, hash = line.strip.split(" ")
      filepath = filepath.join(" ")

      extension = File.extname(filepath)

      next data_file.seek(data_file.pos + size.to_i) if filter_extensions && !filter_extensions.include?(extension)

      # Skip empty files

      next if size.to_i.zero?

      # Read data

      content = data_file.read(size.to_i)

      raise "Incorrect data hash (#{filepath})" unless Digest::MD5.hexdigest(content) == hash

      # Create file and write the data

      filepath = File.join(output_dir, filepath)

      FileUtils.mkdir_p File.dirname(filepath)

      File.write(filepath, content)

      File.utime(Time.now, Time.at(modified_at.to_i), filepath)

      # Report progress

      progress = (line_count.to_f / file_lines.to_f * 100).round(2)

      print "\r\e[KProgress: #{progress}%"
    end

    print "\r\e[KOk\n\n"

    break
  end
rescue => e
  print "\r\e[KFail\n\n"

  raise e
end

def extract_catalogs(root_dir, output_dir, filter_extensions: nil)
  # Extract core catalogs
  dir_path = File.join(root_dir, CORE_CATALOG_GLOB_FILTER)

  Dir[dir_path].each { |path| read_catalog(path, output_dir, filter_extensions: filter_extensions) }

  # Extract mods catalogs
  Dir[File.join(root_dir, "extensions/*")].each do |mod_dir|
    dir_path = File.join(mod_dir, MOD_CATALOG_GLOB_FILTER)

    relative_mod_path = Pathname.new(mod_dir).relative_path_from(Pathname.new(root_dir)).to_s
    mod_output_dir = File.join(output_dir, relative_mod_path)

    Dir[dir_path].each { |path| read_catalog(path, mod_output_dir, filter_extensions: filter_extensions) }
  end
end
